#export params vars
while getopts frcav:t:hnm:peHT: opt; do
    case $opt in
        f) export REDMINE_FORCE=1 ;;
        r) export REDMINE_REBASE=1 ;;
        c) export REDMINE_CHAIN_FINISH=1 ;;
        a) export REDMINE_AUTO_REASSIGN=1 ;;
        v) export VERSION=$OPTARG ;;
        t) export REDMINE_TIME="$OPTARG" ;;
        h) export HELP=1 ;;
        n) export NO_MESSAGE=1 ;;
        p) export REDMINE_TASK_IS_PARENT=1 ;;
        e) export REDMINE_TASK_WITHOUT_PARENT=1 ;;
        H) export REDMINE_HIGHEST_PRIO_ONLY=1 ;;
        T) export HOTFIX_PREFIX_TAG="$OPTARG" ;;
    esac
done
shift $((OPTIND-1))

[ -z $HOTFIX_PREFIX_TAG ] && HOTFIX_PREFIX_TAG=hotfix

function help_command {
  if [ -n "$HELP" ]; then
    CMD=$(basename $0 | /usr/bin/perl -pe 's/\-/ /g')
    if [ -n "$POSSIBLE_ENV" ]; then
      CMD="$POSSIBLE_ENV $CMD"
    fi
    if [ -z "$HELP_NO_OPTION" ]; then
      echo ""
    fi
    echo "    * $CMD $*"
    if [ -z "$HELP_NO_OPTION" ]; then
      help_option_command
    fi
    exit 1
  fi
}

function help_option_command {
    cat <<__EOF__

[OPTIONS]
    * -h => help              : display the help message
    * -f => force             : don't ask question to start / finish / clear
    * -r => rebase            : before starting the review, rebase on origin devel
    * -c => chain             : chain review when finish a task, or finish the release after a start
    * -a => auto reassign     : reassign automatically the task
    * -t => hours spent       : hours spend on a task in decimal format (ex: 2.5, or 1)
    * -n => no message        : skip message edition
    * -p => parent            : indicate that the task is a parent task
    * -e => no parent         : display task without parent
    * -H => highest prio only : display the highest priority of each project only
    * -T => hotfix tag prefix : hotfix tag prefix (default: hotfix)
    
__EOF__
}
