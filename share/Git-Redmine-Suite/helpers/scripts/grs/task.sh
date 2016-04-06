# tasks
function task_update
{
  declare -a PARAMS

  PARAMS+=(--task_id "$task")
  PARAMS+=(--status_ids "$status")
  PARAMS+=(--assigned_to_id "$assigned_to")

  declare -a ADD_PARAMS
  if [ "$status" = "$REDMINE_REVIEW_TODO" ]
    then
    ADD_PARAMS+=(--progress "100")
  elif [ -n "$progress" ]
    then
    ADD_PARAMS+=(--progress "$progress")
  fi

  if [ -n "$notes" ]
    then
    ADD_PARAMS+=(--notes "$notes")
  fi

  if [ -n "$cf_id" ] && [ -n "$cf_val" ]
    then
    ADD_PARAMS+=(--cf_id "$cf_id")
    ADD_PARAMS+=(--cf_val "$cf_val")
  fi

  echo "Updating redmine task $task ..."
    redmine-update-task "${PARAMS[@]}" "${ADD_PARAMS[@]}"
    redmine-check-task "${PARAMS[@]}"
}

function task_start {
  TASK=$1
  if [ -z "$TASK" ]; then
    echo "Missing TASK_NUMBER : "
    echo ""
    HELP=1 exec $0
  fi

  if [ -n "$REDMINE_TASK_IS_PARENT" ]; then
    echo "Find or create subtask for $TASK ..."
    TASK=$(redmine-get-subtask --task_id="$TASK" --status_ids="$REDMINE_TASK_TODO" --cf_id="$REDMINE_GIT_REPOS_ID" --cf_val="$REDMINE_GIT_REPOS_URL" --assigned_to_id="$REDMINE_USER_ID" 2>/dev/null)
    if [ -z "$TASK" ]; then
      echo "Can't find or create the subtask of $1 ..."
      exit 1
    fi
  fi

  git_local_repos_is_clean || exit 1

  if git config redmine.task.$TASK.branch > /dev/null; then
    task_continue "$TASK"
  else
    task_create "$TASK"
  fi

}

function task_continue {
  TASK=$1
  BRNAME=$(git config redmine.task.$TASK.branch)
    echo "Continue the task $TASK ..."
    echo ""
  task=$TASK \
  status=$REDMINE_TASK_IN_PROGRESS \
  assigned_to=$REDMINE_USER_ID \
  cf_id=$REDMINE_GIT_REPOS_ID \
  cf_val=$REDMINE_GIT_REPOS_URL \
  progress=10 \
  task_update || exit 1
    echo ""
    echo "Checkout local branch $BRNAME ..."
    git_refresh_local_repos
    git checkout "$BRNAME"
    git config "redmine.task.current" "$TASK"
}

function task_create {
  TASK=$1

  echo -n "Starting the task : "
  if ! redmine-get-task-info --task_id=$TASK --with_status; then
    exit 1
  fi
  if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to start this task ?"; then
    exit 1
  fi

  task=$TASK \
  status=$REDMINE_TASK_IN_PROGRESS \
  assigned_to=$REDMINE_USER_ID \
  cf_id=$REDMINE_GIT_REPOS_ID \
  cf_val=$REDMINE_GIT_REPOS_URL \
  progress=10 \
  task_update || exit 1

  TASK_TITLE=$(redmine-get-task-info --task_id=$TASK)
  SLUG_TITLE=$(slug --this "$TASK_TITLE")
  BRNAME="redmine-$SLUG_TITLE"

  echo "Creation local branch $BRNAME ..."
  git_refresh_local_repos
  git checkout -b "$BRNAME" origin/devel || git checkout "$BRNAME" || exit 1
  git config "redmine.task.current" "$TASK"
  git config "redmine.task.$TASK.title" "$TASK_TITLE"
  git config "redmine.task.$TASK.branch" "$BRNAME"
  git push origin -u "$BRNAME":"$BRNAME" || cat <<__EOF__
The remote branch $BRNAME already exist !
You have 2 choices. 

Or you take control of this branch :

    git push -fu origin "$BRNAME":"$BRNAME"

Or you get that branch and continue the devel :

    git reset --hard "origin/$BRNAME"
    git push -u origin "$BRNAME":"$BRNAME"

__EOF__


}

function task_status {
  echo "Status of your tasks : "
  echo ""
  CURRENT_TASK=$(git config redmine.task.current)
  for TASK in $(git config --get-regexp ^'redmine\.task\..*\.' | cut -d "." -f 3 | sort -u); do
    if [ "$TASK" == "$CURRENT_TASK" ]; then
      continue
    fi
      T=$(redmine-get-task-info --task_id=$TASK --with_status)
    echo "    $T"
      if echo "$T" | grep -q ", Released with v"; then
        if [ -n "$REDMINE_FORCE" ] || ask_question --question="This task (# $TASK) has been released, clear it ?"; then
          git redmine task clear $TASK
        fi
      fi
         echo ""
  done
  echo ""
}

function task_clear {
  TASK=$1
  if [ -z "$TASK" ]; then
    echo "Missing TASK_NUMBER : "
    echo ""
    HELP=1 exec $0
  fi

  BRNAME=$(git config "redmine.task.${TASK}.branch")
  
  if [ -z "$BRNAME" ]; then
    echo "Invalid task !"
    exit 1
  fi

  git_local_repos_is_clean || exit 1

  echo "Cleaning local and remote dev for task $TASK..."

  git_refresh_local_repos  
  git checkout devel
  git merge origin/devel
  git branch -D "$BRNAME"
  git push origin :"$BRNAME"
  git config --remove-section "redmine.task.$TASK"

  CURRENT_TASK=$(git config redmine.task.current)
  if [ "$TASK" == "$CURRENT_TASK" ]; then
    git config --unset redmine.task.current
  else
    git checkout $(git config redmine.task.$CURRENT_TASK.branch)
  fi

}

function task_depends {
  CURRENT_TASK=$(git config redmine.task.current)

  if [ -z "$CURRENT_TASK" ]; then
    echo "No task started !"
    exit 1
  fi

  DEPS="$@"

  if [ -z "$DEPS" ]; then
    if [ -n "$REDMINE_FORCE" ] || ask_question --question "Do you want to clear the deps of this task ?"; then
      git config --unset redmine.task.$CURRENT_TASK.depends
    fi
  else
    if [ -n "$REDMINE_FORCE" ] || ask_question --question "Do you want to set the deps of this task to '$DEPS' ?"; then
      git config redmine.task.$CURRENT_TASK.depends "$DEPS"
    fi
  fi
}

function task_finish {
  CURRENT_TASK=$(git config redmine.task.current)

  if [ -z "$CURRENT_TASK" ]; then
    echo "No task started !"
    exit 1
  fi

  if [ -z "$(git log origin/devel.. --oneline -n 1)" ]; then
    echo "They is no commit in your branch !"
    echo ""
    echo "To cancel it :"
    echo "    * git redmine task clear $CURRENT_TASK"
    echo ""
    exit 1
  fi

  git_local_repos_is_clean || exit 1
  git_local_repos_is_sync || exit 1

  if [ -n "$REDMINE_FORCE" ] && [ -z "$REDMINE_TIME" ]; then
    echo "Please add a spent time thought parameter with the force option !"
    HELP=1 exec $0
  fi

  if [ -n "$REDMINE_FORCE" ] && ! is_valid_hours --hours="$REDMINE_TIME"; then
    echo "Please enter a valid hours params !"
    HELP=1 exec $0
  fi

  if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to finish the task $CURRENT_TASK ?"; then
    exit 1
  fi

  task=$CURRENT_TASK \
  status=$REDMINE_TASK_IN_PROGRESS \
  assigned_to=$REDMINE_USER_ID \
  cf_id=$REDMINE_GIT_REPOS_ID \
  cf_val=$REDMINE_GIT_REPOS_URL \
  progress=100 \
  task_update || exit 1

  PROJECT=$(redmine-get-task-project-identifier --task_id=$CURRENT_TASK)
  if ! reassigned_this "task" "$PROJECT"; then
    exit 1
  fi

  BRNAME=$(git config redmine.task.$CURRENT_TASK.branch)
  TAG=$(tag_pr --name="$BRNAME")

  set -e
  git_refresh_local_repos
  git checkout "$BRNAME"
  git push origin "$BRNAME":"$BRNAME"
  git tag "$TAG"
  git push origin tags/"$TAG"
  git checkout devel
  git merge origin/devel
  git config --unset "redmine.task.current"
  set +e


  DEPS=$(git config redmine.task.$CURRENT_TASK.depends | perl -pe 's/(\d+)/#$1/g')
  MSG_DEPS=""
  if [ -n "$DEPS" ]; then
      MSG_DEPS="Before reviewing this task, ensure you have already review : $DEPS"
  fi

  if [ -z "$NO_MESSAGE" ] && [ -z "$MESSAGE" ]; then

  F=$(mktemp /tmp/redmine.XXXXXX)
  cat <<__EOF__ > "$F"

###
### Please indicate what the reviewer had to know to do properly his review.
### 
__EOF__
  $EDITOR "$F"

  MESSAGE=$(cat "$F" | grep -v ^"###")
  RET="
"
  fi

  ADDITIONAL_MESSAGE=""
  if [ "$MESSAGE" != "$RET" ] && [ -n "$MESSAGE" ]; then
    ADDITIONAL_MESSAGE="

Additional comments from the developer :

$MESSAGE

"
  fi

  REV_FROM=$(git rev-parse origin/devel)
  REV_TO=$(git rev-parse tags/"$TAG")
  DIFF_URL=$(get_full_diff_url "$REV_FROM" "$REV_TO")

  if [ -n "$DIFF_URL" ]; then
    ADDITIONAL_MESSAGE="$ADDITIONAL_MESSAGE

To view the diff : \"$TAG\":$DIFF_URL

"
  fi

  task=$CURRENT_TASK \
  status=$REDMINE_REVIEW_TODO \
  assigned_to=$ASSIGNED_TO_ID \
  cf_id=$REDMINE_GIT_PR_ID \
  cf_val=$TAG \
  notes="
You can start a review with :
<pre>
git redmine review start $CURRENT_TASK
</pre>

$MSG_DEPS
$ADDITIONAL_MESSAGE
" \
  task_update || exit 1

  echo ""
  [ -e "$F" ] && unlink "$F"

  if [ -z "$REDMINE_FORCE" ] || [ -n "$REDMINE_TIME" ]; then
    if [ -z "$REDMINE_TIME" ]; then
      REDMINE_TIME=$(ask_question --question="How many hours did you spend on the task? " --answer_mode="time")
    fi
    echo "Updating time entry ..."
    redmine-create-task-time --task_id=$CURRENT_TASK --hours=$REDMINE_TIME 2> /dev/null || cat <<__EOF__

Impossible to add a time entry :

  * Time tracking is disabled on this project. Please activate it !

__EOF__
  fi

  if [ -n "$REDMINE_CHAIN_FINISH" ] && [ "$ASSIGNED_TO_ID" = "$REDMINE_USER_ID" ]; then
    exec git redmine review start $CURRENT_TASK
  fi


}

function task_info {
  TASK=$1

  if [ -z "$TASK" ]; then
    HELP=1 exec $0
  fi

  echo "Information on the task $TASK : "
  redmine-get-task-info --task_id=$TASK --status_ids="$REDMINE_TASK_IN_PROGRESS" --with_extended_status
}
