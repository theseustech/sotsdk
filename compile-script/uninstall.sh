clangScript=$(xcrun -find clang)
libtoolScript=$(xcrun -find libtool)
swiftScript=$(xcrun -find swift)

ToolDir="$(dirname "$clangScript")"
sudo rm -f $ToolDir/sot_setup.sh 
sudo rm -f $ToolDir/sot_link.sh 
sudo rm -f $ToolDir/sotcall_exec.sh 
sudo rm -f $ToolDir/sotcall_origin.sh 

if [ -e ${clangScript}_origin ];then
	sudo rm -f "${clangScript}"
	sudo cp -f "${clangScript}_origin" "${clangScript}"
	sudo chmod +x "${clangScript}"
	sudo rm -f "${clangScript}_origin"
fi

if [ -e ${libtoolScript}_origin ];then
	sudo rm -f "${libtoolScript}"
	sudo cp -f "${libtoolScript}_origin" "${libtoolScript}"
	sudo chmod +x "${libtoolScript}"
	sudo rm -f "${libtoolScript}_origin"
fi

if [ -e ${swiftScript}_origin ];then
	sudo rm -f "${swiftScript}"
	sudo cp -f "${swiftScript}_origin" "${swiftScript}"
	sudo chmod +x "${swiftScript}"
	sudo rm -f "${swiftScript}_origin"
fi