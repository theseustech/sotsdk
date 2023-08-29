echo "run sot link, version 1.19"

ReadSot(){
	while [ $(jobs | wc -l) -ge 64 ]; do sleep 1; done
	# "$sotbuilder" "$1" -readir &
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

WhiteFileList=WhiteList_$SotModuleName[@]
BlackFileList=BlackList_$SotModuleName[@]

bIsWhiteListMode=0
bIsBlackListMode=0
for Symbol in "${!WhiteFileList}"
do
	let bIsWhiteListMode=1
	break
done

if [ $bIsWhiteListMode -eq 0 ];then
	for Symbol in "${!BlackFileList}"
	do
		let bIsBlackListMode=1
		break
	done
fi

while read line
do
	OriginalObjFilePath=$line
	OriginalObjFileDir="$(dirname "$OriginalObjFilePath")"
	OriginalObjFileName="$(basename "$OriginalObjFilePath")"
	OriginalObjFileNameNoExt=${OriginalObjFileName%.*}
	OriginFileNameSotExt="${OriginalObjFileNameNoExt}.sot"
	SotOriginalFileInputPath=$OriginalObjFileDir/sot/$OriginFileNameSotExt
	bIsValidIRFile=0
	bIsBlackFile=0
	
	if [ $bIsWhiteListMode -eq 1 ];then
		let bIsBlackFile=1
		for Symbol in "${!WhiteFileList}"
		do
			if [[ $OriginalObjFileNameNoExt == $Symbol ]];then
				let bIsBlackFile=0
				break
			fi
		done
	elif [ $bIsBlackListMode -eq 1 ];then
		for Symbol in "${!BlackFileList}"
		do
			if [[ $OriginalObjFileNameNoExt == $Symbol ]];then
				let bIsBlackFile=1
				break
			fi
		done
	fi
	
	if [ $bIsBlackFile -eq 0 ];then
		# swift gen bitcode file with "bc" extension
		SotSwiftOriginalFileInputPath=$OriginalObjFileDir/${OriginalObjFileNameNoExt}.bc
		if [ -e "$SotSwiftOriginalFileInputPath" ];then
			cp -f "$SotSwiftOriginalFileInputPath" "$SotOriginalFileInputPath"
		fi
		
		if [ -e "$SotOriginalFileInputPath" ];then
			if "$sotbuilder" "$SotOriginalFileInputPath" -check; then
				# ReadSot "$SotOriginalFileInputPath"
				SavedSotFile="$CompileResultSavedDir/$OriginFileNameSotExt"
				cp -f "$SotOriginalFileInputPath" "$SavedSotFile"
				# ReadSot "$SavedSotFile"
				AllBitcodeFiles+=("$SotOriginalFileInputPath")
				bIsValidIRFile=1
				let bHasBitcodeFileIndex=1
				printf "%s\n" "${OriginFileNameSotExt}" >> "$SotsavedLinkListFile"
			else
				echo "check sot file failure: $SotOriginalFileInputPath " 
			fi	
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
	FinalBinObjectFiles=()
	# it's sot injection
	if [ $GenerateSotShip -eq 0 ] && [ $bUseForGenShip -eq 0 ] && [ $EnableSotTest -eq 0 ]; then
		for BCFile in "${AllBitcodeFiles[@]}"
		do
			SotOriginBCFiles+=("$BCFile")
			BCFileName="$(basename "$BCFile")"
			SotOriginBCInjectedFiles+=("$IntermediateOutputDir/$BCFileName.sotinjected")
			# SotOriginBCInjectedFiles+=("$IntermediateOutputDir/$BCFileName")
		done
		for BinObj in "${BinObjectFiles[@]}"
		do
			BinObjFileName="$(basename "$BinObj")"
			SavedSotBinObj="$SavedLinkInjectedFileDir/$BinObjFileName"
			cp -f "$BinObj" "$SavedSotBinObj"
			FinalBinObjectFiles+=("$BinObj")
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
		# ReadSot "$InjectBCFilesLinks"

		ShipBCFilesLinks=$IntermediateOutputDir/ship_link.sot
		"$sotbuilder" -link "${AllBitcodeFiles[@]}" -o "$ShipBCFilesLinks"
		# ReadSot "$ShipBCFilesLinks"
		
		SavedLinkShipFileDir=${SotSavedDir}/ship/${SotModuleName}
		mkdir -p "$SavedLinkShipFileDir"
		ShipIrPath=$SavedLinkShipFileDir/ship.sot
		echo "sot generate ship..."
		"$sotbuilder" "$ShipBCFilesLinks" -sotship -baseir "$InjectBCFilesLinks" -o "$ShipIrPath" -objc -modulename=$SotModuleName -unlinksymbol="got[\s\S]*" \
			"${unlinksymbolOptions[@]}" "${ForceFixFunc_Ship_Options[@]}" "${ForceNoFixFunc_Ship_Options[@]}" "${IgnoreSymbols_Options[@]}" -forcenofixfunc="[\s\S]*CMa"
		
		# ReadSot "${ShipIrPath}"
		if [ -e "$OutputResult" ];then
			echo "don't need sot injecting"
			exit 0
		else
			for BinObj in "${BinObjectFiles[@]}"
			do
				BinObjFileName="$(basename "$BinObj")"
				SavedSotBinObj="$SavedLinkInjectedFileDir/$BinObjFileName"
				FinalBinObjectFiles+=("$SavedSotBinObj")
			done
		fi
	fi

	echo "sot injecting..."

	echo "$sotbuilder" "${SotOriginBCFiles[@]}" -sotinject -objc -modulename=$SotModuleName -outdir="$IntermediateOutputDir" -unlinksymbol="got[\s\S]*" \
		"${unlinksymbolOptions[@]}" "${ForceFixFunc_Inject_Options[@]}" "${ForceNoFixFunc_Inject_Options[@]}" "${IgnoreSymbols_Options[@]}"

	"$sotbuilder" "${SotOriginBCFiles[@]}" -sotinject -objc -modulename=$SotModuleName -outdir="$IntermediateOutputDir" -unlinksymbol="got[\s\S]*" \
		"${unlinksymbolOptions[@]}" "${ForceFixFunc_Inject_Options[@]}" "${ForceNoFixFunc_Inject_Options[@]}" "${IgnoreSymbols_Options[@]}"

	AllInjectedObjPath=()
	for InjectedBCFile in "${SotOriginBCInjectedFiles[@]}"
	do
		# ReadSot $InjectedBCFile
		ObjfilePath=${InjectedBCFile}.o
		AllInjectedObjPath+=("$ObjfilePath")
		while [ $(jobs | wc -l) -ge 64 ]; do sleep 1; done
		"$objbuilder" "${InjectedBCFile}" -filetype=obj --relocation-model=pic -O=2 -o "$ObjfilePath" &
	done
	wait

	exec -a "$0" "$OriginalTool" "${ArgsPassToOrigin[@]}" "${AllInjectedObjPath[@]}" "${FinalBinObjectFiles[@]}" -o "$OutputResult"
else
	. "$NowDir/sotcall_origin.sh"
fi

echo "shouldn't come here"
exit 1
