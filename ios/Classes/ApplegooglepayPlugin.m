#import "ApplegooglepayPlugin.h"
#if __has_include(<applegooglepay/applegooglepay-Swift.h>)
#import <applegooglepay/applegooglepay-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "applegooglepay-Swift.h"
#endif

@implementation ApplegooglepayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftApplegooglepayPlugin registerWithRegistrar:registrar];
}
@end
