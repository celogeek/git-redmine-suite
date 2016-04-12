function release_start {
  declare -a TASKS=($@)

  set -e
  git_refresh_local_repos
  git_local_repos_is_clean
  git checkout master
  git merge origin/master
  git_local_repos_is_sync
  git checkout devel
  git merge origin/devel
  git_local_repos_is_sync
  set +e

  echo ""

  if [ ${#TASKS[@]} -eq 0 ]; then
    git redmine release pending
    if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you want to release these tasks ?"; then
      exit 1
    fi
    TASKS=($(redmine-get-task-list --status_ids="$REDMINE_RELEASE_TODO" --cf_id="$REDMINE_GIT_REPOS_ID" --cf_val="$REDMINE_GIT_REPOS_URL" --ids_only))
    REDMINE_FORCE=1
  fi

  if [ ${#TASKS[@]} -eq 0 ]; then
    echo "Nothing to release !"
    exit 0
  fi

  if [ -z "$VERSION" ]; then
      VERSION=$(next_version --version=$(((git describe --tags --match=v* --abbrev=0 origin/master 2>/dev/null) || echo "v0.00") | /usr/bin/perl -pe 's/^v//' | sort -n | tail -n1))
  fi

  echo "Release V$VERSION with tasks ${TASKS[@]} ..."
  if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Continue ?"; then
    exit 1
  fi

  for TASK in ${TASKS[@]}
  do
      task=$TASK \
      status=$REDMINE_RELEASE_TODO \
      assigned_to=$REDMINE_USER_ID \
      git_repos_id=$GIT_REPOS_ID \
      git_repos_url=$GIT_REPOS_URL \
      task_update || exit 1
  done

  BRNAME="redmine-release-v$VERSION"

  git checkout -b "$BRNAME" origin/devel
  
  git config "redmine.release.version" "$VERSION"
  git config "redmine.release.tasks" "${TASKS[*]}"
  git config "redmine.release.branch" "$BRNAME"
  
  CHANGELOG=$(get_change_log)
  touch "$CHANGELOG"

  tag_version --version="$VERSION" > "$CHANGELOG".new
  cat "$CHANGELOG" >> "$CHANGELOG".new
  mv "$CHANGELOG".new "$CHANGELOG"
  $EDITOR "$CHANGELOG" || exit 1
  git add "$CHANGELOG"
  git commit -m "Add version in Changes"

  if [ -e 'dist.ini' ]
  then
      cat dist.ini | /usr/bin/perl -pe "s/^version(\\s*)=(\\s*)(.*)/version\${1}=\${2}$VERSION/" > dist.ini.new
      mv dist.ini.new dist.ini
      $EDITOR dist.ini || exit 1
      git add dist.ini
      git commit -m 'Update version DistZilla'
  fi

  if [ -e 'VERSION' ]
  then
      echo "$VERSION" > VERSION
      git add VERSION
      git commit -m 'Update version file'
  fi

  git diff --color origin/master | less -R

  cat <<__EOF__
Please edit all the file you need and commit it before finish the release.
Don't forget to run the tests !

You can finish with :

git redmine release finish

or you can abort :

git redmine release abort

__EOF__

  if [ -n "$REDMINE_CHAIN_FINISH" ] ; then
      exec git redmine release finish
  fi  

}

function release_abort {

  VERSION=$(git config redmine.release.version)
  BRNAME=$(git config redmine.release.branch)

  if [ -z "$VERSION" ]; then
    echo "No release started !"
      exit 1
  fi

  git_refresh_local_repos || exit 1
  git_local_repos_is_clean || exit 1

  if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to abort the release $BRNAME ?"; then
    exit 1
  fi
  git config --remove-section redmine.release
  git checkout devel
  git branch -D $BRNAME

}

function release_finish {
  
  VERSION=$(git config redmine.release.version)
  BRNAME=$(git config redmine.release.branch)
  declare -a TASKS=($(git config redmine.release.tasks))

  if [ -z "$VERSION" ]; then
    echo "No release started !"
      exit 1
  fi

  set -e
  git checkout "$BRNAME"
  git_refresh_local_repos
  git_local_repos_is_clean
  git checkout master
  git merge origin/master
  git_local_repos_is_sync
  git checkout devel
  git merge origin/devel
  git_local_repos_is_sync
  set +e


  if [ -z "$REDMINE_CHAIN_FINISH" ] && [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to finish the release of these tasks : ${TASKS[*]} ?"; then
    exit 1
  fi

  echo "Finish the release ${TASKS[@]} ..."

  set -e
  ADDITIONAL_MESSAGE=""
  REV_FROM=$(git rev-parse origin/master)
  git merge --no-ff "$BRNAME" -m "Merge $BRNAME"
  git push origin devel:devel
  git checkout master
  git merge --no-ff devel -m "Merge $BRNAME"
  git tag -fm "release v$V: ${TASKS[*]}" "v$VERSION"
  git push origin master:master
  git push origin "tags/v$VERSION"
  git checkout devel
  git branch -d "$BRNAME"
  git config --remove-section redmine.release
  set +e

  REV_TO=$(git rev-parse origin/devel)
  DIFF_URL=$(get_full_diff_url "$REV_FROM" "$REV_TO")
  if [ -n "$DIFF_URL" ]; then
    ADDITIONAL_MESSAGE="\"View the diff\":$DIFF_URL"
  fi

  echo ""
  echo "Update redmine"
  for TASK in ${TASKS[@]}; do
    echo ""
    echo "Task # $TASK : "

    redmine-get-task-info --task_id="$TASK" --with_status
    echo ""
    
    PROJECT=$(redmine-get-task-project-identifier --task_id=$TASK)
    while true; do
      reassigned_this "release" "$PROJECT" || true
      if [ -z "$ASSIGNED_TO_ID" ]; then
        echo "You need it for the release !"
      else
        break
      fi
    done

      task=$TASK \
      status=$REDMINE_RELEASE_FINISH \
      assigned_to=$ASSIGNED_TO_ID \
      cf_id=$REDMINE_GIT_RELEASE_ID \
      cf_val="$VERSION" \
    notes="
$ADDITIONAL_MESSAGE
" \
      task_update
  done

  
}
