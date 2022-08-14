#import "GeofencingPlugin.h"
#if __has_include(<geofencing/geofencing-Swift.h>)
#import <geofencing/geofencing-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "geofencing-Swift.h"
#endif

@implementation GeofencingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGeofencingPlugin registerWithRegistrar:registrar];
}
@end
