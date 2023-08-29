#pragma once
#include "Modules/ModuleManager.h"

DECLARE_DELEGATE_TwoParams(FSOTApplyPatchDelegate, bool, FString);

class FSOTVMModule : public IModuleInterface
{
public:

	/** IModuleInterface implementation */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
	static bool bSOTVMHasInit;
	static FString SOTVMPatchMD5;
	static FString SOTVMVersionKey;
	SOTVM_API static void InitSOT(const FString& VersionKey, FSOTApplyPatchDelegate ApplyCallback);
	SOTVM_API static void GetSOTPatchInfo(FString& VersionKey, bool& bHasInit, FString& PatchMD5);
};
