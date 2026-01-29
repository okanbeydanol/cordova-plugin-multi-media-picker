declare namespace CordovaPlugins {

  interface MediaPicker {
    /**
     * Gets the current media items.
     * Returns a Promise that resolves with an array of MediaPickerResult.
     */
    /**
     * Options for `getMedias`.
     */
    getMedias(opts?: MediaPickerOptions): Promise<MediaPickerResult[]>;
  }
}

/**
 * Result item returned by getMedias().
 * width / height present for images & videos.
 * duration (in seconds) only for videos.
 */
export interface MediaPickerResult {
  /** Selection order starting at 0 */
  index: number;
  /** Local file URI (file://...) pointing to cached copy */
  uri: string;
  /** Original (copied) file name */
  fileName: string;
  /** File size in bytes */
  fileSize: number;
  /** MIME type like image/jpeg or video/mp4 */
  mimeType: string;
  /** Media type classification */
  type: 'image' | 'video' | 'other';
  /** Pixel width (images/videos only) */
  width?: number;
  /** Pixel height (images/videos only) */
  height?: number;
  /** Duration in seconds (videos only) */
  duration?: number;
}

export interface MediaPickerOptions {
  /** Maximum number of items the user can select (default 3) */
  selectionLimit?: number;
  /** Whether to show an in-app loader while copying files (default true) */
  showLoader?: boolean;
  /** Whether to allow only image selection (default false) */
  imageOnly?: boolean;
  /** Type of media to pick (default 'all') */
  mediaType?: 'all' | 'images' | 'videos';
}

interface CordovaPlugins {
  MediaPicker: CordovaPlugins.MediaPicker;
}

interface Cordova {
  plugins: CordovaPlugins;
}

declare let cordova: Cordova;

export const MediaPicker: CordovaPlugins.MediaPicker;
export as namespace MediaPicker;
declare const _default: CordovaPlugins.MediaPicker;
export default _default;
