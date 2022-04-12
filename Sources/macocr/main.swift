import Cocoa
import Vision

// https://developer.apple.com/documentation/vision/vnrecognizetextrequest

let MODE = VNRequestTextRecognitionLevel.accurate // or .fast
let USE_LANG_CORRECTION = false
var REVISION:Int
if #available(macOS 11, *) {
    REVISION = VNRecognizeTextRequestRevision2
} else {
    REVISION = VNRecognizeTextRequestRevision1
}

var recognitionLanguages = ["zh-CN", "en-US"]
var joiner = ""

func getPasteboardImage() -> NSImage?
{
    let pb = NSPasteboard.general
    let type = NSPasteboard.PasteboardType.tiff
    guard let imgData = pb.data(forType: type) else { return nil }
    
    return NSImage(data: imgData)
}

func postProcessText(str: String) -> String
{
    var newString = str.replacingOccurrences(of: " ", with: "")
    newString = newString.replacingOccurrences(of: ",", with: "，")
    newString = newString.replacingOccurrences(of: ".", with: "。")
    newString = newString.replacingOccurrences(of: ":", with: "：")
    newString = newString.replacingOccurrences(of: "?", with: "？")
    newString = newString.replacingOccurrences(of: "!", with: "！")
    return newString
}


func convertNSImageToCGImage(inputImage: NSImage) -> CGImage? {
    var imageRect = CGRect(x: 0, y: 0, width: inputImage.size.width, height: inputImage.size.height)
    print("===> Get image from pasteboard, width*height \(inputImage.size.width)*\(inputImage.size.height)")
    let cgImage = inputImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    return cgImage
}

func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
        return
    }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    // Process the recognized strings.
    let joined = recognizedStrings.joined(separator: joiner)
    let retString = postProcessText(str: joined)
    print("===> Readout text from image: \(retString)")
    
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(retString, forType: .string)
}


enum DETECTION_STATUS: Int32 {
    case SUCCESS = 0
    case FAILED_CVT_PASTEBOARD = 1
    case FAILED_EMPTY_PASTEBOARD = 2
    case FAILED_REQUEST = 3
}

func detectText() -> DETECTION_STATUS {
    // 这里的if let意思是假如getPasteboardImage返回的不是nil，那么就走{}里面的内容
    if let nsImage = getPasteboardImage(){
        guard let img = convertNSImageToCGImage(inputImage: nsImage) else { 
            return DETECTION_STATUS.FAILED_CVT_PASTEBOARD
        }
      
        let requestHandler = VNImageRequestHandler(cgImage: img)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLanguages = recognitionLanguages
        request.recognitionLevel = MODE
        request.usesLanguageCorrection = USE_LANG_CORRECTION
        request.revision = REVISION
       
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            fputs("Unable to perform the requests: \(error).", stderr)
            return DETECTION_STATUS.FAILED_REQUEST
        }
        return DETECTION_STATUS.SUCCESS
    }
    fputs("No image data checked from pasteboard...\n", stderr)
    return DETECTION_STATUS.FAILED_EMPTY_PASTEBOARD
}

func main() -> Int32 {

    let status = detectText().rawValue

    return status
}
exit(main())
