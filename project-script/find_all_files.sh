SPATH="$1"
SourceFilePattern=".*swift$|.*mm$|.*m$|.*c$|.*cpp$"

FILELIST() {
	filelist=`ls $SPATH`
	for filename in $filelist; do
		echo $filename | grep -q $SourceFilePattern
		if [ -f $filename ];then
			if [[ $filename =~ $SourceFilePattern ]];then
				FileNameNoExt=${filename%.*}
				echo "\"$FileNameNoExt\""
			fi
		elif [ -d $filename ];then
			cd $filename
			SPATH=`pwd`
			FILELIST
			cd ..
		fi
	done
}

cd $SPATH
FILELIST