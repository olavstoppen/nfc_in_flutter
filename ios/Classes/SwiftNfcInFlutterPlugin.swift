import Flutter
import UIKit
import CoreNFC
import NFCSwift

fileprivate let methodChannelName = "nfc_in_flutter"
fileprivate let eventChannelName = "nfc_in_flutter/tags"

func log(_ msg:String)
{
    print(msg)
}

@available(iOS 11.0, *)
extension FlutterError
{
    convenience init(_ error:NFCReaderError)
    {
        self.init(code:error.transferCode,message:error.localizedDescription,details:nil)
    }
    
    convenience init(_ error:Error)
    {
        self.init(code:"SessionError",message:error.localizedDescription,details:nil)
    }
}

@available(iOS 11.0, *)
extension NFCReaderError
{
    var transferCode : String
    {
        switch code
        {
        case .readerErrorUnsupportedFeature: return "NDEFUnsupportedFeatureError"
        case .readerSessionInvalidationErrorUserCanceled: return "UserCanceledSessionError"
        case .readerSessionInvalidationErrorSessionTimeout: return "SessionTimeoutError"
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly: return "SessionTerminatedUnexpectedlyError"
        case .readerSessionInvalidationErrorSystemIsBusy: return "SystemIsBusyError"
        default: return "SessionError"
        }
    }
}

public class SwiftNfcInFlutterPlugin: NSObject, FlutterPlugin 
{
    public static func register(with registrar: FlutterPluginRegistrar)
    {
        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name:eventChannelName, binaryMessenger: registrar.messenger())
        
        let instance = SwiftNfcInFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance.model)
    }
    
    let model = NFCModel()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        model.handle(call,result:result)
    }
}

class NFCModel : NSObject
{
    var events : FlutterEventSink?
    var session : NFCSession?
    
    var isSupported : Bool
    {
        guard #available(iOS 11, *) else { return false }
        return NFCNDEFReaderSession.readingAvailable
    }
    
    var isEnabled : Bool
    {
        return isSupported
    }
    
    func startReading(_ scanOnce:Bool, result:(FlutterResult?)->Void)
    {
        guard isEnabled else { result(nil); return }
        //log(" StartReading, scanOnce = \(scanOnce)");
        if (session != nil)
        {
            log("++ Session != nil, invalidating")
            session?.invalidate()
            session = nil
        }
        
        if session == nil
        {
            if #available(iOS 13.0, *)
            {
                let s = NFCTagReaderSession(pollingOption:[.iso14443,.iso15693,.iso18092],delegate:self,queue:nil) ?? NFCNDEFReaderSession(delegate:self,queue:nil,invalidateAfterFirstRead:scanOnce)
                session = NFCTaggedSessionModel(session:s)
            }
            else if #available(iOS 11.0, *)
            {
                session = NFCSessionModel(session:NFCNDEFReaderSession(delegate:self,queue:nil,invalidateAfterFirstRead:scanOnce))
            }
            else
            {
                session = NFCNotSupportedSessionModel()
            }
        }
        
        session?.begin()
        
        result(nil)
    }
}

// MARK: FlutterMethodHandler

extension NFCModel
{
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        switch (call.method)
        {
        case "readNDEFSupported": result(isSupported)
        case "readNDEFEnabled": result(isEnabled)
        case "startNDEFReading":
            let args = call.arguments as? [String:Any]
            let scanOnce = args?["scan_once"] as? Bool ?? true
            startReading(scanOnce,result:result)
        case "writeNDEF":
            let args = call.arguments as? [String:Any]
            writeToTag(args,result:result)
        default: result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: FlutterStreamHandler

extension NFCModel : FlutterStreamHandler
{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError?
    {
        guard #available(iOS 11, *) else { return FlutterError(code:"NDEFUnsupportedFeatureError",message:nil,details:nil) }
        self.events = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError?
    {
        if session != nil {
            session = nil
        }
        self.events = nil
        return nil
    }
}

// MARK: NFCTagReaderSessionDelegate

@available(iOS 13.0, *)
extension NFCModel : NFCTagReaderSessionDelegate
{
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error)
    {
        log("NFCTagReaderSession Did invalidate with error - \(error)")
        
        self.session = nil
        
        DispatchQueue.main.async { self.events?(FlutterError(error)) }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession)
    {
        log("NFCTagReaderSession did become active")
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag])
    {
         log("Did detect \(tags.count) tags")
        
        guard let tag = tags.first else { return }
        
        switch tag
        {
        case .feliCa(let felicia):
            log("FeliCa tag detected - \(felicia)")
            session.alertMessage = "FeliCa Tags are not supported"
            session.invalidate()
        case .iso7816(let iso):
            log("iso7816 tag detected - \(iso)")
            read(session,didDetectTag:iso,withIdentifier:iso.identifier)
        case .iso15693(let iso):
            log("iso15693 tag detected - \(iso)")
            read(session,didDetectTag:iso,withIdentifier:iso.identifier)
        case .miFare(let mifare):
            log("miFare tag detected - \(mifare)")
            read(session,didDetectTag:mifare,withIdentifier:mifare.identifier)
        @unknown default:
            session.alertMessage = "Tag is not supported"
            session.invalidate()
        }
    }
    
    func read(_ session:NFCTagReaderSession, didDetectTag tag:NFCNDEFTag, withIdentifier identifier:Data)
    {
        if let result = NFCTagResult(data:identifier)
        {
            log("Read Tag identifier - \(result.id)")
            events?(result.dict)
        }
        else
        {
            log("Failed to convert identifier bytes to string")
            session.alertMessage = "Tag is not supported"
            session.invalidate()
        }
    }
}

// MARK: NFCNDEFReaderSessionDelegate

@available(iOS 11.0, *)
extension NFCModel : NFCNDEFReaderSessionDelegate
{
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error)
    {
        //log("Session invalidated with error \(error)")
        self.session = nil
        
        if let error = error as? NFCReaderError
        {
            switch (error.code)
            {
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                DispatchQueue.main.async { self.events?(FlutterEndOfEventStream) }
                return
            default: DispatchQueue.main.async { self.events?(FlutterError(error)) }
            }
        }
        else
        {
            DispatchQueue.main.async { self.events?(FlutterError(error)) }
        }
        //DispatchQueue.main.async { self.events?(FlutterEndOfEventStream) }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage])
    {
        log("Did detect NDEFs")
        
        for message in messages
        {
            let result = message.toResult
            log("result: \(String(describing: result))")
            DispatchQueue.main.async { self.events?(result) }
        }
    }
    
    @available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag])
    {
        log("Detected \(tags.count) tags")
        
        if tags.count > 1
        {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        read(tag:tags.first!,session:session)
        
        if let sess = self.session as? NFCTaggedSessionModel
        {
            sess.lastTag = tags.last
        }
    }

    @available(iOS 13.0, *)
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession)
    {
        let isSetup = self.events != nil ? true : false
        log("Session became active, events: \(isSetup)")
    }
    
    @available(iOS 13.0, *)
    func read(tag:NFCNDEFTag,session:NFCNDEFReaderSession)
    {
        log("Connecting to tag \(tag)")
        
        session.connect(to: tag, completionHandler: { (error: Error?) in
            
            if let error = error
            {
                log("Error: \(error)")
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    return
                } else if nil != error {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage : String
                    if let error = error
                    {
                        statusMessage = "Failed to read NDEF from tag"
                        log("Failed to read NDEF from tag - \(error)")
                    }
                    else if message == nil
                    {
                        statusMessage = "Failed to read NDEF from tag"
                        log("Failed to read NDEF from tag - message is nil")
                    }
                    else
                    {
                        statusMessage = "RFID tag detected"
                        let result = message?.toResult
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            //log("-> Events: \(String(describing: self.events))")
                            self.events?(result)
                        }
                    }
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
    }
}

// MARK: NFC Tag Writing

extension NFCModel
{
    func writeToTag(_ args:[String:Any]?, result:(FlutterResult?)->Void)
    {
        // TODO: Not implemented yet
        result(nil)
    }
}

// MARK: NFC Session

protocol NFCSession
{
    func begin()
    func invalidate()
}

class NFCNotSupportedSessionModel : NFCSession
{
    func begin() {}
    func invalidate(){}
}

class NFCTagResult
{
    let id : String
    
    init(id:String)
    {
        self.id = id
    }
    
    convenience init?(data:Data)
    {
        let id = data.map { String(format:"%02x",$0) }.joined()
        if id.isEmpty { return nil }
        self.init(id:id)
    }
    
    var dict : Dictionary<String,Any>
    {
        return ["id":id]
    }
}

@available(iOS 11.0, *)
class NFCSessionModel : NFCSession
{
    var session : NFCReaderSession
    
    init(session:NFCReaderSession)
    {
        self.session = session
    }
    
    func begin()
    {
        session.begin()
    }
    
    func invalidate()
    {
        session.invalidate()
    }
}

@available(iOS 13.0, *)
class NFCTaggedSessionModel : NFCSessionModel
{
    var lastTag : NFCNDEFTag?
}

// MARK: NFC Message

@available(iOS 11.0, *)
extension NFCNDEFMessage
{
    var toResult : Dictionary<String,Any>?
    {
        var records = Array<Dictionary<String,Any>>()
        var id = ""
        for payload in self.records
        {
            guard let result = payload.toResult else { continue }
            if id.isEmpty
            {
                id = result["id"] as? String ?? ""
            }
            records.append(result)
        }
        return ["id":id,"message_type":"ndef","records":records]
    }
}

@available(iOS 11.0, *)
extension NFCNDEFPayload
{
    var tnf : String
    {
        switch typeNameFormat
        {
        case .empty: return "empty"
        case .nfcWellKnown: return "well_known"
        case .media: return "mime_media"
        case .absoluteURI: return "absolute_uri"
        case .nfcExternal: return "external_type"
        case .unchanged: return "unchanged"
        case .unknown: return "unknown"
        default: return "unknown"
        }
    }
    
    var toResult : Dictionary<String,Any>?
    {
        guard let parsed = NDEFPayloadParser.parse(payload:self) as? NDEFTextPayload else { return nil }
        
        let txt = parsed.text
        let langCode = parsed.langCode
        print("Parsed text: \(txt) Lang code: \(langCode)")
        let payloadBytesLength = payload.count
        var payloadBytes = [CUnsignedChar](repeating:0, count: payloadBytesLength)
        payload.copyBytes(to: &payloadBytes, count: payloadBytesLength)
        
        var id = String(data:identifier,encoding:.utf8) ?? ""
        //id = getTagId()
        if id.isEmpty && parsed.text.hasPrefix(parsed.langCode)
        {
            id = String(parsed.text.dropFirst(parsed.langCode.count))
            while !id.hasPrefix("0")
            {
                id = String(id.dropFirst())
            }
        }
        var res : [String:Any] = ["id":id,"tnf":tnf]
        res["languageCode"] = parsed.langCode
        res["payload"] = parsed.text
        return res
    }
    
    func getTagId() -> String
    {
        var uid: String = ""
        var uuidPadded : Data = identifier
        //We reverse the order
        for (i,_) in uuidPadded.enumerated()
        {
            uuidPadded.insert(uuidPadded.remove(at:i),at:0)
        }
        for (_, element) in uuidPadded.enumerated()
        {
            let tag : String = String(element, radix:16)
            //We add the missing 0 in case the number is < 10. It can be done with bitwise operations too.
            if(tag.count < 2) {
                uid.append("0"+tag)
            }
            else
            {
                uid.append(tag)
            }
        }
        return uid
    }
}

extension String
{
    init(bytesArray: [UInt8], encoding: String.Encoding = .utf8)
    {
        let dataUtf = NSData(bytes: bytesArray, length: bytesArray.count)
        self = String(data: dataUtf as Data, encoding: encoding) ?? ""
    }
}

func subArray(array: [CUnsignedChar], from: Int, length: Int) -> [CUnsignedChar]
{
    if length > 0, array.count-1 >= from+length-1
    {
        let subArray = Array(array[from...from+length-1]) as [CUnsignedChar]
        return subArray
    }
    return [0]
}
