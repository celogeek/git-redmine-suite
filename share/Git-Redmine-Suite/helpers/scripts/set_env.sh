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

set -e

GIT_DIR=$(git rev-parse --git-dir)

cd "$(dirname "$GIT_DIR")"

set +e

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


if [ -z "$REDMINE_AUTHKEY" ] || [ -z "$REDMINE_URL" ]
then
    redmine_help
    exit 1
fi

if 
    [ -z "$REDMINE_TASK_TODO" ]    || [ -z "$REDMINE_TASK_IN_PROGRESS" ]   ||
    [ -z "$REDMINE_REVIEW_TODO" ]  || [ -z "$REDMINE_REVIEW_IN_PROGRESS" ] ||
    [ -z "$REDMINE_RELEASE_TODO" ] || [ -z "$REDMINE_RELEASE_FINISH" ]
then
    redmine_help_with_statuses
    exit 1
fi

if [ "$REDMINE_USER_AUTH_KEY" != "$REDMINE_AUTHKEY" ]; then
    REDMINE_USER_ID=""
    REDMINE_USER_AUTH_KEY=$REDMINE_AUTHKEY
fi

if [ -z "$REDMINE_USER_ID" ]
then
    REDMINE_USER_ID=$(redmine-get-current-user-id)
    git config redmine.user.id $REDMINE_USER_ID
    git config redmine.user.authkey $REDMINE_USER_AUTH_KEY
fi

export REDMINE_AUTHKEY REDMINE_URL
export REDMINE_TASK_TODO REDMINE_TASK_IN_PROGRESS
export REDMINE_REVIEW_TODO REDMINE_REVIEW_IN_PROGRESS
export REDMINE_RELEASE_TODO REDMINE_RELEASE_FINISH
export REDMINE_USER_ID

set -e
