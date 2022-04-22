swift build -c release
sudo /bin/rm -rf /usr/local/bin/ocr
sudo cp .build/arm64-apple-macosx/release/macocr /usr/local/bin/ocr
