function get_change_log {
    C="Changes"
    for i in Changes changes Changelog ChangeLog
    do
        [ -e "$i" ] && C="$i" && break
    done
    echo $C
}