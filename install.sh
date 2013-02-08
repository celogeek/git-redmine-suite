#!/bin/bash
cd "$(dirname "$0")"
[ "x$SKIP_CPANM" == "x" ] && sudo PERL_CPANM_OPT="" ./cpanm -nv Redmine::API MooX::Options LWP::Protocol::https
sudo rm -rf /usr/local/share/Weborama-Git-Review /usr/local/share/Git-Redmine-Suite /usr/local/bin/git-review /usr/local/bin/git-review-* /usr/local/bin/git-task /usr/local/bin/git-task-* /usr/local/bin/git-project /usr/local/bin/git-project-* /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

sudo mkdir -p /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av helpers/* /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av bin/* /usr/local/bin/
sudo chmod +x /usr/local/share/Git-Redmine-Suite/helpers/* /usr/local/bin/git-review /usr/local/bin/git-review-* /usr/local/bin/git-task /usr/local/bin/git-task-* /usr/local/bin/git-project /usr/local/bin/git-project-* /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*
