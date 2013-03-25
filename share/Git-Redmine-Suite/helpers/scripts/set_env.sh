function redmine_help
{
    cat <<__EOF__
Please configure your redmine instance :
    git config --global redmine.authkey YOUR_AUTH_KEY
    git config --global redmine.url THE_REDMINE_URL_SERVER

__EOF__
}

function redmine_help_with_statuses
{
    cat <<__EOF__
Please configure your redmine instance :
    git config --global redmine.statuses.task.assigned ID
    git config --global redmine.statuses.task.inprogress ID
    git config --global redmine.statuses.review.assigned ID
    git config --global redmine.statuses.review.inprogress ID
    git config --global redmine.statuses.release.assigned ID
    git config --global redmine.statuses.release.finish ID

__EOF__
    redmine-get-statuses-ids
    echo ""
}

GIT_DIR=$(git rev-parse --git-dir)

if [ -z $GIT_DIR ]; then
    exit 1
fi

cd "$(dirname "$GIT_DIR")"

REDMINE_GIT_REPOS_URL=$(git config remote.origin.url)

REDMINE_AUTHKEY=$(git config redmine.authkey)
REDMINE_URL=$(git config redmine.url)

REDMINE_USER_ID=$(git config redmine.user.id)
REDMINE_USER_AUTH_KEY=$(git config redmine.user.authkey)

REDMINE_TASK_TODO=$(git config redmine.statuses.task.assigned)
REDMINE_TASK_IN_PROGRESS=$(git config redmine.statuses.task.inprogress)

REDMINE_REVIEW_TODO=$(git config redmine.statuses.review.assigned)
REDMINE_REVIEW_IN_PROGRESS=$(git config redmine.statuses.review.inprogress)

REDMINE_RELEASE_TODO=$(git config redmine.statuses.release.assigned)
REDMINE_RELEASE_FINISH=$(git config redmine.statuses.release.finish)

REDMINE_GIT_REPOS_ID=$(git config redmine.git.repos)
REDMINE_GIT_PR_ID=$(git config redmine.git.pr)
REDMINE_GIT_RELEASE_ID=$(git config redmine.git.release)

REDMINE_PRIO_COLOR=$(git config redmine.priocolor)

export REDMINE_PRIO_COLOR

if [ -z "$REDMINE_AUTHKEY" ] || [ -z "$REDMINE_URL" ]; then
    redmine_help
    exit 1
fi

export REDMINE_AUTHKEY REDMINE_URL

if 
    [ -z "$REDMINE_TASK_TODO" ]    || [ -z "$REDMINE_TASK_IN_PROGRESS" ]   ||
    [ -z "$REDMINE_REVIEW_TODO" ]  || [ -z "$REDMINE_REVIEW_IN_PROGRESS" ] ||
    [ -z "$REDMINE_RELEASE_TODO" ] || [ -z "$REDMINE_RELEASE_FINISH" ]; then
    redmine_help_with_statuses
    exit 1
fi

export REDMINE_TASK_TODO REDMINE_TASK_IN_PROGRESS
export REDMINE_REVIEW_TODO REDMINE_REVIEW_IN_PROGRESS
export REDMINE_RELEASE_TODO REDMINE_RELEASE_FINISH

if [ "$REDMINE_USER_AUTH_KEY" != "$REDMINE_AUTHKEY" ]; then
    REDMINE_USER_ID=""
    REDMINE_USER_AUTH_KEY=$REDMINE_AUTHKEY
    REDMINE_GIT_REPOS_ID=""
    REDMINE_GIT_PR_ID=""
    REDMINE_GIT_RELEASE_ID=""
fi

if [ -z "$REDMINE_USER_ID" ]; then
    REDMINE_USER_ID=$(redmine-get-current-user-id)
    git config redmine.user.id $REDMINE_USER_ID
    git config redmine.user.authkey $REDMINE_USER_AUTH_KEY
fi

export REDMINE_USER_ID

if [ -z "$REDMINE_GIT_REPOS_ID" ] || [ -z "$REDMINE_GIT_PR_ID" ] || [ -z "$REDMINE_GIT_RELEASE_ID" ]; then
    redmine-get-project-cf | grep "^git config" | /bin/bash
    REDMINE_GIT_REPOS_ID=$(git config redmine.git.repos)
    REDMINE_GIT_PR_ID=$(git config redmine.git.pr)
    REDMINE_GIT_RELEASE_ID=$(git config redmine.git.release)
fi

export REDMINE_GIT_REPOS_ID REDMINE_GIT_REPOS_URL REDMINE_GIT_PR_ID REDMINE_GIT_RELEASE_ID

#export params vars
while getopts frcav:t: opt; do
    case $opt in
        f) export REDMINE_FORCE=1 ;;
        r) export REDMINE_REBASE=1 ;;
        c) export REDMINE_CHAIN_FINISH=1 ;;
        a) export REDMINE_AUTO_REASSIGN=1 ;;
        v) export VERSION=$OPTARG ;;
        t) export REDMINE_TIME=$OPTARG ;;
    esac
done

shift $((OPTIND-1))
