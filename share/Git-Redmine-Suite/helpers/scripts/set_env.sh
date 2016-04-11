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
    redmine-get-project-cf | grep "^git config" | /usr/bin/env bash
    REDMINE_GIT_REPOS_ID=$(git config redmine.git.repos)
    REDMINE_GIT_PR_ID=$(git config redmine.git.pr)
    REDMINE_GIT_RELEASE_ID=$(git config redmine.git.release)
fi

export REDMINE_GIT_REPOS_ID REDMINE_GIT_REPOS_URL REDMINE_GIT_PR_ID REDMINE_GIT_RELEASE_ID

export EDITOR=$(git var GIT_EDITOR)

if [ -z "$EDITOR" ]; then
  echo "Can't find a valid editor !"
  echo "Please setup the EDITOR vars manually"
  exit 1
fi

if [ "$(basename "$EDITOR")" == "vi" ]; then
  echo "\"vi\" doesnt return a proper error code"
  echo "Please change your editor :"
  echo "  * git config --global core.editor \$(which vim)"
  exit 1
fi

REDMINE_PRIO_COLOR=$(git config redmine.priocolor)

if [ -z "$REDMINE_PRIO_COLOR" ]; then
    REDMINE_PRIO_COLOR=$(get_priocolor)
    if [ -n "$REDMINE_PRIO_COLOR" ]; then
        git config redmine.priocolor "$REDMINE_PRIO_COLOR"
    fi
fi

export REDMINE_PRIO_COLOR

REDMINE_UUID=$(git config --global redmine.uuid)

if [ -z "$REDMINE_UUID" ]; then
    REDMINE_UUID=$(generate_uuid)
    git config --global redmine.uuid "$REDMINE_UUID"
fi

REDMINE_GIT_DIFF=$(git config redmine.diff)

export REDMINE_GIT_DIFF
