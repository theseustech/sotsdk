# this script use for copy ship to main bundle, add it to run script of build phase
# $1 is sotconfig.sh's path
# $2 is the sotsaved folder path
# $3~n is the module name
# for example: 
# sh /Users/sotsdk-1.0/project-script/sot_package.sh "$SOURCE_ROOT/sotconfig.sh" "$SOURCE_ROOT/sotsaved/$CONFIGURATION" modulename1 modulename2 modulename3
NowDir="$(dirname "$0")"

SotConfigPath="$1"
SotsavedBaseDir="$2"
EnableSotTest=0
if [ -e $SotConfigPath ];then
	. "$SotConfigPath"
else
	echo "sotconfig not exist."
	exit 1
fi

if [ ! -e $SotsavedBaseDir ];then
	echo "sotsaved not exist."
	exit 0
fi

if [[ "$sotbuilder" == "" || ! -e $sotbuilder ]];then
	clangScript=$(xcrun -find clang)
	ToolDir="$(dirname "$clangScript")"
	sotbuilder="$ToolDir/sotbuilder"
fi

let ModuleCount=$#-2
ModuleNames=${@:3:$ModuleCount}
for Arch in $ARCHS
do
	# delete old sot ship
	ShipBundlePath="$BUILT_PRODUCTS_DIR/${PRODUCT_NAME}.app/sotship_${Arch}.sot"
	echo "ship in bundle path: ${ShipBundlePath}"
	if [ -e "$ShipBundlePath" ];then
		echo "sotpackage delete old ship"
		rm "$ShipBundlePath"
	fi

	# found all the sub ship
	SotsavedDir="$SotsavedBaseDir/$Arch"
	NeedCombineShips=()
	ShipCount=0
	for ModuleName in ${ModuleNames[@]}
	do
		ModuleShipFilePath="$SotsavedDir/ship/${ModuleName}/ship.sot"
		if [ -e "$ModuleShipFilePath" ];then
			NeedCombineShips+=("$ModuleShipFilePath")
			let ShipCount+=1
		fi
	done 

	if [ $EnableSot -eq 0 ];then
		continue
	fi
	
	if [ $GenerateSotShip -eq 0 ] && [ $EnableSotTest -eq 0 ];then
		continue
	fi
	# generate ship to bundle
	if [ $ShipCount -eq 1 ];then
		echo "${Arch} only one ship: ${NeedCombineShips[0]}, just copy"
		cp -f "${NeedCombineShips[0]}" "$ShipBundlePath"
	elif [ $ShipCount -gt 1 ];then
		echo "${Arch} has multiple ships, combine them:"
		for ShipFile in "${NeedCombineShips[@]}"
		do
			echo "$ShipFile"
		done
		$sotbuilder -combine "${NeedCombineShips[@]}" -o "$ShipBundlePath"
	else
		echo "${Arch} has no ship, sotpackage do nothing"
	fi
done

exit 0