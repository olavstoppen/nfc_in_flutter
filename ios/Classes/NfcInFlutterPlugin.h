#import <Flutter/Flutter.h>
#import <CoreNFC/CoreNFC.h>

@protocol NFCWrapper <FlutterStreamHandler>
- (void)startReading:(BOOL)once;
- (BOOL)isEnabled;
- (void)writeToTag:(NSDictionary* _Nonnull)data completionHandler:(void (^_Nonnull) (FlutterError * _Nullable error))completionHandler;
@end


@interface NfcInFlutterPlugin : NSObject<FlutterPlugin>

@property(nonatomic,strong) NSObject<NFCWrapper>* _Nonnull wrapper;

@property(nonatomic,strong) FlutterEventSink _Nullable events;

@end

API_AVAILABLE(ios(11))
@interface NFCWrapperBase : NSObject <FlutterStreamHandler>

@property(nonatomic,strong) FlutterEventSink _Nullable events;
@property(nonatomic,strong) NFCNDEFReaderSession* _Nullable session;

- (void)readerSession:(nonnull NFCNDEFReaderSession *)session didInvalidateWithError:(nonnull NSError *)error;

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events;

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments;

- (NSDictionary * _Nonnull)formatMessageWithIdentifier:(NSString* _Nonnull)identifier message:(NFCNDEFMessage* _Nonnull)message;

- (NFCNDEFMessage * _Nonnull)formatNDEFMessageWithDictionary:(NSDictionary* _Nonnull)dictionary;
@end

API_AVAILABLE(ios(11))
@interface NFCWrapperImpl : NFCWrapperBase <NFCWrapper, NFCNDEFReaderSessionDelegate> {
    FlutterMethodChannel* methodChannel;
    dispatch_queue_t dispatchQueue;
}
-(id _Nullable )init:(FlutterMethodChannel*_Nonnull)methodChannel dispatchQueue:(dispatch_queue_t _Nonnull )dispatchQueue;
@end

API_AVAILABLE(ios(13))
@interface NFCWritableWrapperImpl : NFCWrapperImpl

@property (atomic, retain) __kindof id<NFCNDEFTag> _Nullable lastTag;

@end

@interface NFCUnsupportedWrapper : NSObject <NFCWrapper>
@end
