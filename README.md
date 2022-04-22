# macocr

OCR command line utility for macOS 10.15+. Utilizes the [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest) API.

## Build and Run

```
swift build
swift run
```

If `-c release` is not used, then the executable may be located at: `./.build/debug/macocr`

If you want to replace `/usr/local/bin/ocr`, please delete it first and then copy the release executable file again.
