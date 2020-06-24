#import "RtspviewPlugin.h"
#if __has_include(<rtspview/rtspview-Swift.h>)
#import <rtspview/rtspview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "rtspview-Swift.h"
#endif

@implementation RtspviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRtspviewPlugin registerWithRegistrar:registrar];
}
@end
