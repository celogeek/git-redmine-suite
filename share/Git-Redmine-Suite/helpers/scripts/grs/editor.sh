function check_valid_editor {
	if ([ -z "$EDITOR" ] || [ ! -x "$EDITOR" ]) && [ -z "$REDMINE_FORCE" ]; then
		echo "No valid editor found !"
		echo "Please set \$EDITOR to a valid one"
		echo ""
		exit 1
	fi	
}