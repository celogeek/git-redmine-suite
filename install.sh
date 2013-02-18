#!/bin/bash
cd "$(dirname "$0")"
[ "x$SKIP_CPANM" == "x" ] && sudo PERL_CPANM_OPT="" ./cpanm -nv Redmine::API Moo MooX::Options LWP::Protocol::https Version::Next Encode DateTime
sudo rm -rf /usr/local/share/Git-Redmine-Suite usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

sudo mkdir -p /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av helpers/* /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av bin/* /usr/local/bin/
sudo chmod +x /usr/local/share/Git-Redmine-Suite/helpers/* /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

POD2MAN=$(/usr/bin/perl -E 'say "/usr/bin/pod2man", sprintf("%d.%d",split(/\./, sprintf("%vd",$^V)))')
[ -x $POD2MAN ] || POD2MAN=/usr/bin/pod2man
for F in /usr/local/share/Git-Redmine-Suite/helpers/pod/guide/*.pod
do
    echo "Pod2Man : $F ..."
    $POD2MAN "$F" "${F/.pod/.man}"
done
