#import <Foundation/Foundation.h>
#import "callsot.h"
#import "SotWebService.h"
@implementation CallSot:NSObject
-(void) InitSot
{
    [SotWebService ApplyBundlePatch];
}
@end
