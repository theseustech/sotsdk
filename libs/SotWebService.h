#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, SotDownloadScriptStatus) {
    SotScriptStatusSuccess = 1,
    SotScriptStatusFailure = 2,
    SotScriptStatusError = 3,
    SotScriptApplyError = 4,
    SotScriptShipDisable = 5,
    SotScriptShipHasSyncNewer = 6,
    SotScriptShipAlreadyNewest = 7,
};

typedef void (^SotOnlineScriptStatusCallback)(SotDownloadScriptStatus);

typedef struct _SotApplyCachedResult
{
    bool Success;
    NSString* ShipMD5;
}SotApplyCachedResult;

@interface SotWebService : NSObject

//only works for free version
+(bool) ApplyBundleShip;

//only works for website version
+(void) Sync:(NSString *)version_key is_dev:(bool)is_dev cb:(SotOnlineScriptStatusCallback)cb;

//only works for website version
+(SotApplyCachedResult) ApplyCachedAndPullShip:(NSString *)version_key is_dev:(bool)is_dev cb:(SotOnlineScriptStatusCallback)cb;

//only works for website version
+(void) PullShip:(NSString *)version_key is_dev:(bool)is_dev cb:(SotOnlineScriptStatusCallback)cb;

//only works for enterprise version
+(bool) ApplyShipByData:(char*) bytes length:(NSUInteger)length;

//release all the sotship
+(void) Release;

@end

NS_ASSUME_NONNULL_END
