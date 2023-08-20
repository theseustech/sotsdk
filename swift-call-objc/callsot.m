#import <Foundation/Foundation.h>
#import "callsot.h"
#import "../sotsdk/libs/SotWebService.h"
@implementation CallSot:NSObject
-(void) InitSot
{
#ifdef USE_SOT
   SotApplyCachedResult ApplyShipResult = [SotWebService ApplyCachedAndPullShip:@"16669eb8c1cec46d" is_dev:false cb:^(SotDownloadScriptStatus status)
    {
        if(status == SotScriptShipAlreadyNewest)
        {
            NSLog(@"SyncOnly SotScriptShipAlreadyNewest");
        }
        else if(status == SotScriptShipHasSyncNewer)
        {
            NSLog(@"SyncOnly SotScriptShipHasSyncNewer");
        }
        else if(status == SotScriptShipDisable)
        {
            NSLog(@"SyncOnly SotScriptShipDisable");
        }
        else
        {
            NSLog(@"SyncOnly SotScriptStatusFailure");
        }
    }];

    if(ApplyShipResult.Success)
    {
        if(ApplyShipResult.ShipMD5)
            NSLog(@"sot success apply cached ship md5:%@", ApplyShipResult.ShipMD5);
    }
#endif
}
@end
