#include "SOTVM.h"
#if PLATFORM_IOS
#include "../../../libs/SotWebService.h"
#endif
#define LOCTEXT_NAMESPACE "FSOTVMModule"

bool FSOTVMModule::bSOTVMHasInit = false;
FString FSOTVMModule::SOTVMPatchMD5;
FString FSOTVMModule::SOTVMVersionKey;

void FSOTVMModule::StartupModule()
{}

void FSOTVMModule::ShutdownModule()
{}

void FSOTVMModule::GetSOTPatchInfo(FString& VersionKey, bool& bHasInit, FString& PatchMD5)
{
	VersionKey = SOTVMVersionKey;
	bHasInit = bSOTVMHasInit;
	PatchMD5 = SOTVMPatchMD5;
}

void FSOTVMModule::InitSOT(const FString& VersionKey, FSOTApplyPatchDelegate ApplyCallback)
{
#if PLATFORM_IOS
	SOTVMVersionKey = VersionKey;
	NSString* NSVerKey = [NSString stringWithUTF8String: TCHAR_TO_UTF8(*VersionKey)];
	dispatch_async(dispatch_get_main_queue(), ^{

		SotApplyCachedResult ApplyShipResult = [SotWebService ApplyCachedAndPullShip:NSVerKey is_dev:false cb:^(SotDownloadScriptStatus status)
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
			{
	            NSLog(@"sot success apply cached ship md5:%@", ApplyShipResult.ShipMD5);
				FString MD5Str(ApplyShipResult.ShipMD5);
				bSOTVMHasInit = true;
				SOTVMPatchMD5 = MD5Str;
				AsyncTask(ENamedThreads::GameThread, [=](){
						ApplyCallback.ExecuteIfBound(true, MD5Str);
					});
			}
	    }
	});
#endif
}

#if PLATFORM_IOS
void SOTVMInitForEngine(NSString* VersionKey)
{
	FSOTVMModule::SOTVMVersionKey = VersionKey;
	SotApplyCachedResult ApplyShipResult = [SotWebService ApplyCachedAndPullShip:VersionKey is_dev:false cb:^(SotDownloadScriptStatus status)
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
		{
            NSLog(@"sot success apply cached ship md5:%@", ApplyShipResult.ShipMD5);
			FString MD5Str(ApplyShipResult.ShipMD5);
			FSOTVMModule::bSOTVMHasInit = true;
			FSOTVMModule::SOTVMPatchMD5 = MD5Str;
		}
    }
}
#endif

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSOTVMModule, SOTVM)