//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_baidu_mapapi_base/FlutterBmfbasePlugin.h>)
#import <flutter_baidu_mapapi_base/FlutterBmfbasePlugin.h>
#else
@import flutter_baidu_mapapi_base;
#endif

#if __has_include(<flutter_baidu_mapapi_map/FlutterBmfmapPlugin.h>)
#import <flutter_baidu_mapapi_map/FlutterBmfmapPlugin.h>
#else
@import flutter_baidu_mapapi_map;
#endif

#if __has_include(<flutter_baidu_mapapi_search/FlutterBmfsearchPlugin.h>)
#import <flutter_baidu_mapapi_search/FlutterBmfsearchPlugin.h>
#else
@import flutter_baidu_mapapi_search;
#endif

#if __has_include(<flutter_bmflocation/FlutterBmflocationPlugin.h>)
#import <flutter_bmflocation/FlutterBmflocationPlugin.h>
#else
@import flutter_bmflocation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterBmfbasePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBmfbasePlugin"]];
  [FlutterBmfmapPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBmfmapPlugin"]];
  [FlutterBmfsearchPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBmfsearchPlugin"]];
  [FlutterBmflocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBmflocationPlugin"]];
}

@end
