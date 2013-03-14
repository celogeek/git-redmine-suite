
# GLOBAL
function help_command {
	if [ -n "$HELP" ]; then
		CMD=$(basename $0 | /usr/bin/perl -pe 's/\-/ /g')
		echo "    * $CMD $*"
		exit 1
	fi
}

# GUIDE
function guide_show {
	man $MAN_DIR/$1.man
}