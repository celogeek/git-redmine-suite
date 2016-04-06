function git_refresh_local_repos {
  git fetch -ap
  git fetch --tags -p
}

function git_has_local_changes {
  git_status=$(git status --untracked-files=no --porcelain)
  if [ -n "$git_status" ]
  then
    echo "Your local branch is not clean:"
    echo "$git_status"
    echo ""
    echo "Please commit and push first."
    return 1
  fi

  git_remote_tracking=$(git config branch.$(git name-rev --name-only HEAD).remote)
  if [ -n "$git_remote_tracking" ]
    then
    git_cherry=$(git cherry -v --abbrev)
    if [ -n "$git_cherry" ]
    then
      echo "There is pending commit:"
      echo "$git_cherry"
      echo ""
      echo "Please push this first ..."
      return 1
    fi
  fi

  return 0
}