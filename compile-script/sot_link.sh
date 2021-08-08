echo "run sot link"

ReadSot(){
	"$sotbuilder" "$1" -readir &
}

LinkeFileListPath=${AllArgsArr[$LinkFileListIndex]}

bHasBitcodeFileIndex=0
AllBitcodeFiles=()
BinObjectFiles=()

SotModuleName=${AllArgsArr[$ArgSotModuleNameIndex]}
SotSavedDir=${AllArgsArr[$SotSavedDirIndex]}
SavedLinkInjectedFileDir=${SotSavedDir}/injected/${SotModuleName}
CompileResultSavedDir=$SavedLinkInjectedFileDir

let bUseForGenShip=0
if [ ! $SotBaseModuleIndex -eq -1 ];then
	SotBaseModuleName=${AllArgsArr[$SotBaseModuleIndex]}
	SavedLinkInjectedFileDir=${SotSavedDir}/injected/${SotBaseModuleName}
	let bUseForGenShip=1
fi

if [ $GenerateSotShip -eq 0 ] && [ $bUseForGenShip -eq 0 ]; then
	echo
else
	CompileResultSavedDir=${SotSavedDir}/ship/${SotModuleName}
fi
mkdir -p "$CompileResultSavedDir"

SotsavedLinkListFile=$CompileResultSavedDir/LinkList.txt
rm -f "$SotsavedLinkListFile"

IntermediateOutputDir="$(dirname "$LinkeFileListPath")/sot"
mkdir -p "$IntermediateOutputDir"

while read line
do
	OriginalObjFilePath=$line
	OriginalObjFileDir="$(dirname "$OriginalObjFilePath")"
	OriginalObjFileName="$(basename "$OriginalObjFilePath")"
	OriginalObjFileNameNoExt=${OriginalObjFileName%.*}
	OriginFileNameSotExt="${OriginalObjFileNameNoExt}.sot"
	SotOriginalFileInputPath=$OriginalObjFileDir/sot/$OriginFileNameSotExt
	bIsValidIRFile=0
	if [ ! -e "$SotOriginalFileInputPath" ];then
		# swift gen bitcode file with "bc" extension
		SotSwiftOriginalFileInputPath=$OriginalObjFileDir/${OriginalObjFileNameNoExt}.bc
		if [ -e "$SotSwiftOriginalFileInputPath" ];then
			cp -f "$SotSwiftOriginalFileInputPath" "$SotOriginalFileInputPath"
		fi
	fi
	if [ -e "$SotOriginalFileInputPath" ];then
		if "$sotbuilder" "$SotOriginalFileInputPath" -check; then
			ReadSot "$SotOriginalFileInputPath"
			SavedSotFile="$CompileResultSavedDir/$OriginFileNameSotExt"
			cp -f "$SotOriginalFileInputPath" "$SavedSotFile"
			AllBitcodeFiles+=("$SotOriginalFileInputPath")
			bIsValidIRFile=1
			let bHasBitcodeFileIndex=1
			printf "%s\n" "${OriginFileNameSotExt}" >> "$SotsavedLinkListFile"
		fi	
	fi
	if [ $bIsValidIRFile -eq 0 ];then
		BinObjectFiles+=("$OriginalObjFilePath")
	fi
done < "$LinkeFileListPath"

if [ ! $bHasBitcodeFileIndex -eq 0 ];then
	let bShouldRunSotBuild=1
else
	echo "don't have any llvmir file, skip sot process"
	let bShouldRunSotBuild=0
fi

if [ $bShouldRunSotBuild -eq 1 ];then
	# echo "allbitcodefiles:" "${AllBitcodeFiles[@]}"
	# add sotbuilder options************************************************
	# 1.
	unlinksymbolOptions=()
	unlinksymbolsArray=UnlinkSymbols_$SotModuleName[@]
	for Symbol in "${!unlinksymbolsArray}"
	do
		unlinksymbolOptions+=("-unlinksymbol=$Symbol")
	done
	# 2.
	ForceFixFunc_Inject_Options=()
	ForceFixFunc_Inject_SymArr=ForceFixFunc_Inject_$SotModuleName[@]
	for Symbol in "${!ForceFixFunc_Inject_SymArr}"
	do
		ForceFixFunc_Inject_Options+=("-forcefixfunc=$Symbol")
	done
	# 3.
	ForceNoFixFunc_Inject_Options=()
	ForceNoFixFunc_Inject_SymArr=ForceNoFixFunc_Inject_$SotModuleName[@]
	for Symbol in "${!ForceNoFixFunc_Inject_SymArr}"
	do
		ForceNoFixFunc_Inject_Options+=("-forcenofixfunc=$Symbol")
	done
	# 4.
	ForceFixFunc_Ship_Options=()
	ForceFixFunc_Ship_SymArr=ForceFixFunc_Ship_$SotModuleName[@]
	for Symbol in "${!ForceFixFunc_Ship_SymArr}"
	do
		ForceFixFunc_Ship_Options+=("-forcefixfunc=$Symbol")
	done
	# 5.
	ForceNoFixFunc_Ship_Options=()
	ForceNoFixFunc_Ship_SymArr=ForceNoFixFunc_Ship_$SotModuleName[@]
	for Symbol in "${!ForceNoFixFunc_Ship_SymArr}"
	do
		ForceNoFixFunc_Ship_Options+=("-forcenofixfunc=$Symbol")
	done
	# 6.
	IgnoreSymbols_Options=()
	IgnoreSymbols_SymArr=IgnoreSymbols_$SotModuleName[@]
	for Symbol in "${!IgnoreSymbols_SymArr}"
	do
		IgnoreSymbols_Options+=("-ignore=$Symbol")
	done
	# **********************************************************************
	
	SotOriginBCFiles=()
	SotOriginBCInjectedFiles=()
	# it's sot injection
	if [ $GenerateSotShip -eq 0 ] && [ $bUseForGenShip -eq 0 ] && [ $EnableSotTest -eq 0 ]; then
		for BCFile in "${AllBitcodeFiles[@]}"
		do
			SotOriginBCFiles+=("$BCFile")
			BCFileName="$(basename "$BCFile")"
			SotOriginBCInjectedFiles+=("$IntermediateOutputDir/$BCFileName.sotinjected")
		done
	# it's sot ship generation
	else
		SotInjectedLinkListFile=$SavedLinkInjectedFileDir/LinkList.txt
		while read line
		do
			SotBCFilePath=$SavedLinkInjectedFileDir/$line
			SotOriginBCFiles+=("$SotBCFilePath")
			SotOriginBCInjectedFiles+=("$IntermediateOutputDir/$line.sotinjected")
		done < "$SotInjectedLinkListFile"
		
		InjectBCFilesLinks=$IntermediateOutputDir/injected_link.sot
		"$sotbuilder" -link "${SotOriginBCFiles[@]}" -o "$InjectBCFilesLinks"
		ReadSot "$InjectBCFilesLinks"
		ShipBCFilesLinks=$IntermediateOutputDir/ship_link.sot
		"$sotbuilder" -link "${AllBitcodeFiles[@]}" -o "$ShipBCFilesLinks"
		SavedLinkShipFileDir=${SotSavedDir}/ship/${SotModuleName}
		mkdir -p "$SavedLinkShipFileDir"
		ShipIrPath=$SavedLinkShipFileDir/ship.sot
		echo "sot generate ship..."
		"$sotbuilder" "$ShipBCFilesLinks" -sotship -baseir "$InjectBCFilesLinks" -o "$ShipIrPath" -objc -modulename=$SotModuleName -unlinksymbol="got[\s\S]*" \
			"${unlinksymbolOptions[@]}" "${ForceFixFunc_Ship_Options[@]}" "${ForceNoFixFunc_Ship_Options[@]}" "${IgnoreSymbols_Options[@]}"

		ReadSot "${ShipIrPath}"
	fi

	echo "sot injecting..."
	"$sotbuilder" "${SotOriginBCFiles[@]}" -sotinject -objc -modulename=$SotModuleName -outdir="$IntermediateOutputDir" -unlinksymbol="got[\s\S]*" \
		"${unlinksymbolOptions[@]}" "${ForceFixFunc_Inject_Options[@]}" "${ForceNoFixFunc_Inject_Options[@]}" "${IgnoreSymbols_Options[@]}"

	AllInjectedObjPath=()
	for InjectedBCFile in "${SotOriginBCInjectedFiles[@]}"
	do
		ObjfilePath=${InjectedBCFile}.o
		AllInjectedObjPath+=("$ObjfilePath")		
		"$objbuilder" "${InjectedBCFile}" -filetype=obj --relocation-model=pic -o "$ObjfilePath" &
	done
	wait

	exec -a "$0" "$OriginalTool" "${ArgsPassToOrigin[@]}" "${AllInjectedObjPath[@]}" "${BinObjectFiles[@]}" -o "$OutputResult"
else
	. "$NowDir/sotcall_origin.sh"
fi

echo "shouldn't come here"
exit 1