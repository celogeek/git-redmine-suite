function git_refresh_local_repos {
	git fetch -ap
	git fetch --tags -p
}