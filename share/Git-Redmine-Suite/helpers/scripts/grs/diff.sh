function get_full_diff_url {
	get_diff_url --diff-url="$REDMINE_GIT_DIFF" --git-remote-url="$REDMINE_GIT_REPOS_URL" --ref_from="$1" --ref_to="$2"
}