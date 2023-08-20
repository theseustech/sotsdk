ScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

clangScript=$(xcrun -find clang)
libtoolScript=$(xcrun -find libtool)
swiftScript=$(xcrun -find swift)
if [ -e "${swiftScript}-frontend" ];then
	swiftScript="${swiftScript}-frontend"
fi

ToolDir="$(dirname "$clangScript")"
sudo cp -f "$ScriptDir/sot_setup.sh" "$ToolDir/sot_setup.sh"
sudo cp -f "$ScriptDir/sot_link.sh" "$ToolDir/sot_link.sh"
sudo cp -f "$ScriptDir/sotcall_exec.sh" "$ToolDir/sotcall_exec.sh"
sudo cp -f "$ScriptDir/sotcall_origin.sh" "$ToolDir/sotcall_origin.sh"
sudo cp -f "$ScriptDir/../builder/sotbuilder" "$ToolDir/sotbuilder"
sudo cp -f "$ScriptDir/../builder/objbuilder" "$ToolDir/objbuilder"

if [ ! -e ${clangScript}_origin ];then
	echo "copy ${clangScript} to ${clangScript}_origin"
	sudo cp -f "${clangScript}" "${clangScript}_origin"
	sudo chmod +x "${clangScript}_origin"
fi

if [ ! -e ${libtoolScript}_origin ];then
	echo "copy ${libtoolScript} to ${libtoolScript}_origin"
	sudo cp -f "${libtoolScript}" "${libtoolScript}_origin"
	sudo chmod +x "${libtoolScript}_origin"
fi

if [ ! -e ${swiftScript}_origin ];then
	echo "copy ${swiftScript} to ${swiftScript}_origin"
	sudo cp -f "${swiftScript}" "${swiftScript}_origin"
	sudo chmod +x "${swiftScript}_origin"
fi

sudo cp -f "$ScriptDir/clang" "$clangScript"
sudo cp -f "$ScriptDir/libtool" "$libtoolScript"
sudo cp -f "$ScriptDir/swift" "$swiftScript"

sudo chmod +x "$clangScript"
sudo chmod +x "$libtoolScript"
sudo chmod +x "$swiftScript"