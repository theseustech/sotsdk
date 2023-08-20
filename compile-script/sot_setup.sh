NowDir="$(dirname "$0")"
let ArgIndex=0
let ArgOutputIndex=-1
ArgOutputIndexs=()
OriginOutputFile=()
let ArgSotModuleNameIndex=-1
let LinkFileListIndex=-1
let SotSavedDirIndex=-1
let SotConfigIndex=-1
let SotBaseModuleIndex=-1
let SkipArgToOriginCount=0
let OutfileIndex=-1

let bIsSotModule=0
let bIsLinking=0
let SkipSotArgsCount=0
let SkipThisFile=-1
AllArgsArr=()
ArgsPassToOrigin=()
ArgsPassExcludeSotArgs=()
SotModuleName=""
SotConfigFilePath=""

for arg in "$@"
do
  # echo $arg
  AllArgsArr[$ArgIndex]=$arg
  if [ "$arg" == "-o" ]
  then
  	let ArgOutputIndex=$ArgIndex+1
    ArgOutputIndexs+=($ArgOutputIndex)
  	let SkipArgToOriginCount+=2
  fi

  if [ "$arg" == "-sotmodule" ]
  then
  	let ArgSotModuleNameIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
    let SkipSotArgsCount+=2
    let bIsSotModule=1
  fi

  if [ "$arg" == "-sotsaved" ]
  then
  	let SotSavedDirIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
    let SkipSotArgsCount+=2
  fi

  if [ "$arg" == "-filelist" ] && [ $FromClang -eq 1 ];then
  	let LinkFileListIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
  	let bIsLinking=1
  fi

  if [ "$arg" == "-sotconfig" ]
  then
  	let SotConfigIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
    let SkipSotArgsCount+=2
  fi

  if [ "$arg" == "-sotbasemodule" ]
  then
    let SotBaseModuleIndex=$ArgIndex+1
    let SkipArgToOriginCount+=2
    let SkipSotArgsCount+=2
  fi

  if [ "$arg" == "-output-filelist" ] && [ $FromSwift -eq 1 ];then
    let OutfileIndex=$ArgIndex+1
    let SkipArgToOriginCount+=2
  fi

  # if [ "$arg" == "-Xfrontend" ];then
  #   continue
  # fi

  # if [ "$arg" == "-Xllvm" ];then
  #   continue
  # fi

  if [[ $SotModuleName == "" ]] && [[ "$arg" == *"-Dsotmodule="* ]];then
    SotModuleName=${arg#-Dsotmodule=}
  fi

  if [[ $SotModuleName == "" ]] && [[ "$arg" == *"sotmodule="* ]];then
    SotModuleName=${arg#sotmodule=}
  fi

  if [[ $SotConfigFilePath == "" ]] && [[ "$arg" == *"-Dsotconfig="* ]];then
    SotConfigFilePath=${arg#-Dsotconfig=}
  fi

  if [[ $SotConfigFilePath == "" ]] && [[ "$arg" == *"sotconfig="* ]];then
    SotConfigFilePath=${arg#sotconfig=}
  fi

  if [ "$arg" == "-experimental-skip-non-inlinable-function-bodies-without-types" ];then
    let SkipThisFile=1
  fi

  if [ "$arg" == "-experimental-skip-non-inlinable-function-bodies" ];then
    let SkipThisFile=1
  fi

  if [ $SkipArgToOriginCount -eq 0 ]
  then
    ArgsPassToOrigin+=("$arg")
  else
  	let SkipArgToOriginCount-=1
  fi

  if [ $SkipSotArgsCount -eq 0 ]
  then
    ArgsPassExcludeSotArgs+=("$arg")
  else
    let SkipSotArgsCount-=1
  fi

  let ArgIndex+=1
done


# echo $ArgsPassToOrigin
clangRetCode=0
EnableSot=0
EnableSotTest=0
GenerateSotShip=0

if [[ $SotConfigFilePath == "" ]] && [ ! $SotConfigIndex -eq -1 ];then
  SotConfigFilePath=${AllArgsArr[$SotConfigIndex]}
fi

if [[ $SotModuleName == "" ]] && [ ! $bIsSotModule -eq -1 ];then
  SotModuleName=${AllArgsArr[$bIsSotModule]}
fi

if [[ $SotConfigFilePath == "" ]];then
  let EnableSot=0
else
  if [ -e "$SotConfigFilePath" ];then
  	. "$SotConfigFilePath"

    if [ -e "$NowDir/sotbuilder" ];then
      sotbuilder=$NowDir/sotbuilder
    fi
    if [ -e "$NowDir/objbuilder" ];then
      objbuilder=$NowDir/objbuilder
    fi
  else
    echo "error: sotconfig doesn't exist!:" "$SotConfigFilePath"
  fi
fi

OutputResult=""

if [ $EnableSot -eq 1 ];then
  if [ $bIsLinking -eq 1 ];then
    if [ $SotSavedDirIndex -eq -1 ] || [ $ArgOutputIndex -eq -1 ] || [ $ArgSotModuleNameIndex -eq -1 ];then
      let EnableSot=0
    fi
  fi
fi

SotBinOutputFiles=()

if [ $EnableSot -eq 1 ];then
  if [ ! $ArgOutputIndex -eq -1 ];then
    OutputResult=${AllArgsArr[$ArgOutputIndex]}
    IntermediateOutputDir="$(dirname "$OutputResult")"
    IntermediateOutputDir=$IntermediateOutputDir/sot
    mkdir -p "$IntermediateOutputDir"

    let i=0
    for EveryArgOutputIndex in "${ArgOutputIndexs[@]}"
    do
      EveryOutputResult=${AllArgsArr[$EveryArgOutputIndex]}
      EveryOutputFileName="$(basename "$EveryOutputResult")"  
      EveryOutputFileNameNoExtension="${EveryOutputFileName%.*}"  
      EveryOutputFileExtension="${OutputFileName##*.}"  
      if [ "$EveryOutputFileExtension" == "swiftmodule" ];then
        let EnableSot=0
      fi
      SotBinOutputFiles+=("-o" "$IntermediateOutputDir/$EveryOutputFileNameNoExtension.sot")
      OriginOutputFile+=("-o" "$EveryOutputResult")
    done

    if [ $SkipThisFile -eq 1 ];then
      let EnableSot=0
    fi
  fi

  SwiftSotOutputArgs=()
  if [ ! $OutfileIndex -eq -1 ];then
    SwiftOutputFilePath=${AllArgsArr[$OutfileIndex]}

    if [ -e "$SwiftOutputFilePath" ];then
      SwiftOutputFileDirPath="$(dirname "$SwiftOutputFilePath")"
      mkdir -p "$SwiftOutputFileDirPath/sot"
      SOTOutputFilePath="$SwiftOutputFileDirPath/sot/sotoutputfiles"
      rm -f "$SOTOutputFilePath"
      while read line
      do
        OriginalObjFilePath=$line
        OriginalObjFileDir="$(dirname "$OriginalObjFilePath")"
        OriginalObjFileName="$(basename "$OriginalObjFilePath")"
        OriginalObjFileNameNoExt=${OriginalObjFileName%.*}
        OriginFileNameSotExt="${OriginalObjFileNameNoExt}.sot"
        SotOriginalFileInputPath=$OriginalObjFileDir/sot/$OriginFileNameSotExt
        printf "%s\n" "${SotOriginalFileInputPath}" >> "$SOTOutputFilePath"
      done < "$SwiftOutputFilePath"
      SwiftSotOutputArgs+=("-output-filelist" "$SOTOutputFilePath")
    else
      let EnableSot=0
    fi
  fi
fi
