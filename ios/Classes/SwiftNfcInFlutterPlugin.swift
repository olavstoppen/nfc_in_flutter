import Flutter
import UIKit
import CoreNFC
import VYNFCKit

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
        
        if (session != nil)
        {
            session?.invalidate()
            session = nil
        }
        
        if session == nil
        {
            if #available(iOS 13.0, *)
            {
                session = NFCTaggedSessionModel(session:NFCNDEFReaderSession(delegate:self,queue:nil,invalidateAfterFirstRead:scanOnce))
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
    
    var events : FlutterEventSink?
    var session : NFCSession?
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
        session?.invalidate()
        session = nil
        events = nil
        return nil
    }
}

// MARK: NFCNDEFReaderSessionDelegate

@available(iOS 11.0, *)
extension NFCModel : NFCNDEFReaderSessionDelegate
{
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error)
    {
        log("Session invalidated with error \(error)")
        
        self.session = nil
        
        if let error = error as? NFCReaderError
        {
            switch (error.code)
            {
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                events?(FlutterEndOfEventStream)
                return
            default: events?(FlutterError(error))
            }
        }
        else
        {
            events?(FlutterError(error))
        }
        
        events?(FlutterEndOfEventStream)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage])
    {
        log("Did detect NDEFs")
        
        for message in messages
        {
            let result = message.toResult
            DispatchQueue.main.async { self.events?(result) }
        }
    }
    
    @available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag])
    {
        log("Did detect tags")
        
        for tag in tags
        {
            session.connect(to:tag)
            { error in
                if let error = error
                {
                    log("Tag Connection Error: \(error)")
                    return
                }
                
                tag.readNDEF()
                { msg, error in
                    if let error = error
                    {
                        log("Tag Read Error: \(error)")
                        return
                    }
                    if let message = msg
                    {
                        let result = message.toResult
                        DispatchQueue.main.async { self.events?(result) }
                    }
                    else
                    {
                        log("Tag Read Message was nil")
                    }
                }
            }
        }
        
        if let sess = self.session as? NFCTaggedSessionModel
        {
            sess.lastTag = tags.last
        }
    }

    @available(iOS 13.0, *)
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession)
    {
         log("Session became active")
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

@available(iOS 11.0, *)
class NFCSessionModel : NFCSession
{
    var session : NFCNDEFReaderSession
    
    init(session:NFCNDEFReaderSession)
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
        guard let parsed = VYNFCNDEFPayloadParser.parse(self) as? VYNFCNDEFTextPayload else { return nil }

        var id = String(data:identifier,encoding:.utf8) ?? ""
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
}
