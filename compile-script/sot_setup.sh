let ArgIndex=0
let ArgOutputIndex=-1
let ArgSotModuleNameIndex=-1
let LinkFileListIndex=-1
let SotSavedDirIndex=-1
let SotConfigIndex=-1
let SotBaseModuleIndex=-1
let SkipArgToOriginCount=0

let bIsSotModule=0
let bIsLinking=0
AllArgsArr=()
ArgsPassToOrigin=()

for arg in "$@"
do
  # echo $arg
  AllArgsArr[$ArgIndex]=$arg
  if [ "$arg" == "-o" ]
  then
  	let ArgOutputIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
  fi

  if [ "$arg" == "-sotmodule" ]
  then
  	let ArgSotModuleNameIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
    let bIsSotModule=1
  fi

  if [ "$arg" == "-sotsaved" ]
  then
  	let SotSavedDirIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
  fi

  if [ "$arg" == "-filelist" ]
  then
  	let LinkFileListIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
  	let bIsLinking=1
  fi

  if [ "$arg" == "-sotconfig" ]
  then
  	let SotConfigIndex=$ArgIndex+1
  	let SkipArgToOriginCount+=2
  fi

  if [ "$arg" == "-sotbasemodule" ]
  then
    let SotBaseModuleIndex=$ArgIndex+1
    let SkipArgToOriginCount+=2
  fi

  if [ $SkipArgToOriginCount -eq 0 ]
  then
    ArgsPassToOrigin+=("$arg")
  else
  	let SkipArgToOriginCount-=1
  fi

  let ArgIndex+=1
done
# echo $ArgsPassToOrigin
clangRetCode=0
EnableSot=0
EnableSotTest=0
GenerateSotShip=0
if [ ! $SotConfigIndex -eq -1 ] && [ $bIsSotModule -eq 1 ];then
	SotConfigFilePath=${AllArgsArr[$SotConfigIndex]}		
  if [ -e "$SotConfigFilePath" ];then
  	. "$SotConfigFilePath"
  else
    echo "error: sotconfig doesn't exist!"
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

if [ $EnableSot -eq 1 ] && [ ! $ArgOutputIndex -eq -1 ];then
  OutputResult=${AllArgsArr[$ArgOutputIndex]}
  IntermediateOutputDir="$(dirname "$OutputResult")"
  IntermediateOutputDir=$IntermediateOutputDir/sot
  mkdir -p "$IntermediateOutputDir"
  OutputFileName="$(basename "$OutputResult")"  
  OutputFileNameNoExtension="${OutputFileName%.*}"  
  # OutputFileName=${OutputFileName%.*}
fi
