// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.IO;

public class SOTVM : ModuleRules
{
	public SOTVM(ReadOnlyTargetRules Target) : base(Target)
	{
// 		Type = ModuleType.CPlusPlus;
		PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;
		PublicDependencyModuleNames.AddRange(
			new string[]
				{
					"Core",
				}
			);


		PrivateDependencyModuleNames.AddRange(
			new string[]
				{
					"CoreUObject",
					"Engine",
				}
			);

		PublicIncludePaths.Add(ModuleDirectory);
		
        if (Target.Platform == UnrealTargetPlatform.IOS)
		{
    	    string SDKPath = Path.GetFullPath(Path.Combine(ModuleDirectory, "../../../"));
			string LibSotWebPath = Path.Combine(SDKPath, "libs/libsot_web.a");
            PublicAdditionalLibraries.Add(LibSotWebPath);
            PublicIncludePaths.Add(Path.Combine(SDKPath, "libs"));
        }
    }
}
