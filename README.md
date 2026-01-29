# [Cordova Media Picker](https://github.com/okanbeydanol/cordova-plugin-multi-media-picker) [![Release](https://img.shields.io/npm/v/cordova-plugin-multi-media-picker.svg?style=flat)](https://github.com/okanbeydanol/cordova-plugin-multi-media-picker/releases)

Cordova Media Picker lets users select multiple images and videos with a simple Promise-based API:
- iOS: uses PHPicker (modern, no deprecated UI, respects selectionLimit).
- Android: uses a custom in‑app picker (enforces selectionLimit) or system picker (limit trimmed).
- Returns array of `{ index, uri, fileName, fileSize, mimeType, type, width?, height?, duration? }` (files copied into app cache).
- Optional loader overlay while files are processed.

Requirements: Cordova iOS 6+, Cordova Android 11+. Platforms supported:

## Plugin setup

Using this plugin requires [Cordova iOS](https://github.com/apache/cordova-ios) and [Cordova Android](https://github.com/apache/cordova-android).

1. `cordova plugin add cordova-plugin-multi-media-picker`--save


### Usage

Usage
JavaScript (Global Cordova)
After the device is ready, you can use the plugin via the global `cordova.plugins.MediaPicker` object:

```javascript
document.addEventListener('deviceready', async function () {
  var MediaPicker = cordova.plugins.MediaPicker;

  const options = {
    selectionLimit: 3,   // default 3
    showLoader: true     // default true
    imageOnly: true      // default false
    mediaType : "all"   // videos, images or all(default all)
  };

  try {
    const results = await MediaPicker.getMedias(options);
    // Sort by original picking order (index)
    results.sort((a, b) => a.index - b.index);

    console.log('Picked media:', results);
    // Each item: { index: number, uri: 'file:///...' }
  } catch (err) {
    console.error('Media picking failed:', err);
  }
});
```

* Check the [JavaScript source](https://github.com/okanbeydanol/cordova-plugin-multi-media-picker/tree/master/www/MediaPicker.js) for additional configuration.


TypeScript / ES Module / Ionic
You can also use ES module imports (with TypeScript support):

```typescript
interface MediaPickerResult {
  index: number;          // selection order (0-based)
  uri: string;            // file:// path to cached copy
  fileName: string;       // original filename
  fileSize: number;       // bytes
  mimeType: string;      // e.g., image/jpeg, video/mp4
  type: 'image' | 'video' | 'other';
  width?: number;         // images & videos
  height?: number;        // images & videos
  duration?: number;      // seconds (videos only)
}

import { MediaPicker, MediaPickerResult } from 'cordova-plugin-multi-media-picker';

async function pick() {
  const results: MediaPickerResult = await MediaPicker.getMedias({
    selectionLimit: 4,
    showLoader: true,
    imageOnly: true
  });

  const ordered = results.sort((a, b) => a.index - b.index);
  console.log(ordered);
}
```
TypeScript Types
Type definitions are included. You get full autocompletion and type safety in TypeScript/Ionic projects.


* Check the [Typescript definitions](https://github.com/okanbeydanol/cordova-plugin-multi-media-picker/tree/master/www/MediaPicker.d.ts) for additional configuration.

Notes

iOS: width/height extracted via UIImage / AVAsset; duration from AVAsset (seconds).
Android: width/height/duration populated when available via MediaMetadataRetriever / Exif.
Files are temporary copies in app cache. Delete them when no longer needed.
If user picks more than selectionLimit on Android system picker, extras are trimmed (or blocked in custom in‑app picker).
Use imageOnly: true to restrict to images (videos ignored).

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/cordova). (Tag `cordova`)
- If you **found a bug** or **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.



## Contributing

Patches welcome! Please submit all pull requests against the master branch. If your pull request contains JavaScript patches or features, include relevant unit tests. Thanks!

## Copyright and license

    The MIT License (MIT)

    Copyright (c) 2024 Okan Beydanol

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
