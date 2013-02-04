#!/bin/bash
cd "$(dirname "$0")"
[ "x$SKIP_CPANM" == "x" ] && sudo PERL_CPANM_OPT="" ./cpanm -nv Redmine::API
sudo rm -rf /usr/local/share/Weborama-Git-Review/helpers/ /usr/local/bin/git-review /usr/local/bin/git-review-* /usr/local/bin/git-task /usr/local/bin/git-task-*
sudo mkdir -p /usr/local/share/Weborama-Git-Review/helpers/
sudo cp -av helpers/* /usr/local/share/Weborama-Git-Review/helpers/
sudo cp -av bin/* /usr/local/bin/
sudo chmod +x /usr/local/share/Weborama-Git-Review/helpers/* /usr/local/bin/git-review /usr/local/bin/git-review-* /usr/local/bin/git-task /usr/local/bin/git-task-*
