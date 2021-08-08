# this script is use for call original tool with original options
if [ ! $ArgOutputIndex -eq -1 ];then
	ArgsPassToOrigin+=("-o" "${AllArgsArr[$ArgOutputIndex]}")
fi
if [ ! $LinkFileListIndex -eq -1 ];then
	ArgsPassToOrigin+=("-filelist" "${AllArgsArr[$LinkFileListIndex]}")
fi

exec -a "$0" "$OriginalTool" "${ArgsPassToOrigin[@]}"