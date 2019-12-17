#import "NfcInFlutterPlugin.h"
#if __has_include(<nfc_in_flutter/nfc_in_flutter-Swift.h>)
#import <nfc_in_flutter/nfc_in_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nfc_in_flutter-Swift.h"
#endif

@implementation NfcInFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNfcInFlutterPlugin registerWithRegistrar:registrar];
}
@end
