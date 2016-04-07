function piwik_call {

  CMD=$(basename $0)
  GIT_VERSION=$(git version | /usr/bin/perl -pe 's/.*?(\d+(\.\d+)+)$/$1/')

  declare -a CMD_OPTIONS

    [ -n "$REDMINE_FORCE" ]       && CMD_OPTIONS+=("Force")
    [ -n "$REDMINE_REBASE" ]       && CMD_OPTIONS+=("Rebase")
    [ -n "$REDMINE_CHAIN_FINISH" ]     && CMD_OPTIONS+=("Chain")
    [ -n "$REDMINE_AUTO_REASSIGN" ]   && CMD_OPTIONS+=("AutoReassign")
    [ -n "$VERSION" ]           && CMD_OPTIONS+=("CustomVersion")
    [ -n "$NO_MESSAGE" ]         && CMD_OPTIONS+=("SkipMessage")
    [ -n "$REDMINE_TASK_IS_PARENT" ]   && CMD_OPTIONS+=("CreateSubTask")

  declare -a PARAMS
  PARAMS+=(--server_url "$REDMINE_URL")
  PARAMS+=(--uuid "$REDMINE_UUID")
  PARAMS+=(--version "$CURRENT_VERSION")
  PARAMS+=(--git_version "$GIT_VERSION")
  PARAMS+=(--action "$CMD")

  if [ "${#CMD_OPTIONS[@]}" -ne 0 ]; then
    PARAMS+=(--action_options "${CMD_OPTIONS[*]}")
  fi  

  piwik "${PARAMS[@]}" 2>/dev/null 1>/dev/null &
}