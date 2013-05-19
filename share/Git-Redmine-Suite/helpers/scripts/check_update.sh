UPDATE_CHECK_FILE=$(check_update_file)
if [ ! -f "$UPDATE_CHECK_FILE" ]
then
    touch "$UPDATE_CHECK_FILE"
    echo "Checking update ..."
    MASTER_VERSION=$(curl -s "https://raw.github.com/celogeek/git-redmine-suite/master/VERSION")
    CURRENT_VERSION=$(cat "$ROOT_DIR/VERSION")
    if [ -n "$MASTER_VERSION" ] && [ "$MASTER_VERSION" != "$CURRENT_VERSION" ]
    then
        echo "A new version is available : $MASTER_VERSION ( Current: $CURRENT_VERSION )"
        echo ""
        echo "The changelog : "
        echo ""
        get_changes --version="$CURRENT_VERSION"
        if ask_question --question="Do you want to upgrade ?"
        then
            echo "Updating ..."
            echo ""
            exec git redmine self-upgrade $0 $*
        else
            echo "I will ask you to upgrade tomorrow ..."
            echo ""
        fi
    fi
fi