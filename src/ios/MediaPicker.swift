import Foundation
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import AVFoundation

@objc(MediaPicker)
class MediaPicker: CDVPlugin, PHPickerViewControllerDelegate {

    private var commandCallbackId: String?

    private var selectionLimitOpt: Int = 3
    private var showLoaderOpt: Bool = true
    private var imageOnlyOpt: Bool = false
    private var mediaTypeOpt : String = "all" // ✅ Ajouté

    private weak var overlayView: UIView?
    private weak var overlaySpinner: UIActivityIndicatorView?

    @objc(getMedias:)
    func getMedias(command: CDVInvokedUrlCommand) {
        self.commandCallbackId = command.callbackId

        if let opts = command.argument(at: 0) as? [String: Any] {
            if let limit = opts["selectionLimit"] as? Int { selectionLimitOpt = max(1, limit) }
            if let show = opts["showLoader"] as? Bool { showLoaderOpt = show }
            if let imageOnly = opts["imageOnly"] as? Bool { imageOnlyOpt = imageOnly }
            if let mediaType = opts["mediaType"] as? String { mediaTypeOpt = mediaType }
            else {
                // si mediatype n'est pas défini par l'utilisateur, prendre en compte la valeur de imageOnly
                mediaTypeOpt = imageOnlyOpt ? "images" : "all";
            }
        }

        guard let presentingVC = self.viewController else {
            let result = CDVPluginResult(status: .error, messageAs: "No presenting view controller")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        // ✅ Prevent multiple picker presentations
        if presentingVC.presentedViewController is PHPickerViewController {
            let result = CDVPluginResult(status: .error, messageAs: "Picker is already presented")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            // if imageOnlyOpt {
            //     config.filter = .images
            // } else {
            //     config.filter = .any(of: [.images, .videos])
            // }

            switch mediaTypeOpt {
            case "images": config.filter = .images
            break;

            case "videos" : config.filter = .videos
            break;

            default:  config.filter = .any(of: [.images, .videos])
                
            } 

            config.selectionLimit = selectionLimitOpt

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            presentingVC.present(picker, animated: true, completion: nil)
        } else {
            let result = CDVPluginResult(status: .error, messageAs: "iOS < 14 not supported")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    private func showLoader(on view: UIView) {
        guard showLoaderOpt else { return }
        DispatchQueue.main.async {
            let overlay = UIView(frame: view.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)

            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            spinner.translatesAutoresizingMaskIntoConstraints = false

            overlay.addSubview(spinner)
            view.addSubview(overlay)

            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])

            self.overlayView = overlay
            self.overlaySpinner = spinner
        }
    }

    private func hideLoader() {
        DispatchQueue.main.async {
            self.overlaySpinner?.stopAnimating()
            self.overlayView?.removeFromSuperview()
        }
    }
    
    @available(iOS 14.0, *)
    private func resolveMime(provider: NSItemProvider, dest: URL) -> String {
        var candidates: [String] = []

        // iOS 16+: use modern ContentTypes first
        if #available(iOS 16.0, *) {
            candidates.append(contentsOf: provider.registeredContentTypes.compactMap { $0.preferredMIMEType })
        }

        // Always fallback to legacy identifiers
        candidates.append(contentsOf: provider.registeredTypeIdentifiers.compactMap { UTType($0)?.preferredMIMEType })

        // Add dest file UTI if available
        if let uti = try? dest.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let ut = UTType(uti),
           let mime = ut.preferredMIMEType {
            candidates.append(mime)
        }

        // Preferences
        if candidates.contains("image/jpeg") {
            return "image/jpeg"
        }
        if candidates.contains("video/mp4") {
            return "video/mp4"
        }

        return candidates.first ?? "application/octet-stream"
    }

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.isEmpty {
            picker.dismiss(animated: true) {
                let result = CDVPluginResult(status: .ok, messageAs: [])
                self.commandDelegate.send(result, callbackId: self.commandCallbackId)
            }
            return
        }

        self.showLoader(on: picker.view)

        let group = DispatchGroup()
        let lock = NSLock()
        var medias: [[String: Any]] = []
        var errorMessages: [String] = []

        func addError(_ message: String) {
            lock.lock()
            errorMessages.append(message)
            lock.unlock()
        }

        func normalizeFileURL(_ url: URL) -> String {
            if url.scheme?.lowercased() == "file" {
                return url.absoluteString
            } else {
                return "file://\(url.path)"
            }
        }

        for (tapIndex, res) in results.enumerated() {
            let provider = res.itemProvider
            let isVideo = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            let isImage = provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)

            let typeIdentifier: String
            if isVideo {
                typeIdentifier = UTType.movie.identifier
            } else if isImage {
                typeIdentifier = UTType.image.identifier
            } else {
                typeIdentifier = provider.registeredTypeIdentifiers.first ?? UTType.data.identifier
            }

            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (sourceURL, error) in
                defer { group.leave() }

                if let error = error {
                    addError("Item \(tapIndex) load error: \(error.localizedDescription)")
                    return
                }
                guard let sourceURL = sourceURL else {
                    addError("Item \(tapIndex) no sourceURL")
                    return
                }

                let fm = FileManager.default
                let ext = sourceURL.pathExtension.isEmpty
                    ? (isVideo ? "mov" : "jpeg")
                    : sourceURL.pathExtension

                let dest = fm.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_\(tapIndex).\(ext)")

                do {
                    if fm.fileExists(atPath: dest.path) {
                        try fm.removeItem(at: dest)
                    }
                    try fm.copyItem(at: sourceURL, to: dest)
                    let normalized = normalizeFileURL(dest)
                    var info: [String: Any] = [
                        "index": tapIndex,
                        "uri": normalized,
                        "fileName": dest.lastPathComponent,
                        "fileSize": (try? fm.attributesOfItem(atPath: dest.path)[.size] as? Int) ?? 0
                    ]
                    info["mimeType"] = self.resolveMime(provider: provider, dest: dest)
                    if isImage {
                        info["type"] = "image"
                        if let img = UIImage(contentsOfFile: dest.path) {
                            info["width"] = Int(img.size.width)
                            info["height"] = Int(img.size.height)
                        }
                    } else if isVideo {
                        info["type"] = "video"
                        let asset = AVAsset(url: dest)
                        let duration = CMTimeGetSeconds(asset.duration)
                        info["duration"] = duration

                        if let track = asset.tracks(withMediaType: .video).first {
                            let size = track.naturalSize.applying(track.preferredTransform)
                            info["width"] = Int(abs(size.width))
                            info["height"] = Int(abs(size.height))
                        }
                    } else {
                        info["type"] = "other"
                    }
                    lock.lock()
                    medias.append(info)
                    lock.unlock()
                } catch {
                    addError("Item \(tapIndex) copy error: \(error.localizedDescription)")
                }
            }
        }

        group.notify(queue: .main) {
            self.hideLoader()

            picker.dismiss(animated: true) {
                if !errorMessages.isEmpty {
                    let result = CDVPluginResult(status: .error, messageAs: errorMessages.joined(separator: "\n"))
                    self.commandDelegate.send(result, callbackId: self.commandCallbackId)
                    return
                }

                let sorted = medias.sorted { ($0["index"] as? Int ?? 0) < ($1["index"] as? Int ?? 0) }

                let result = CDVPluginResult(status: .ok, messageAs: sorted)
                self.commandDelegate.send(result, callbackId: self.commandCallbackId)
            }
        }
    }
}
