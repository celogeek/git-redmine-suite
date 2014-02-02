#!/bin/bash

GIT_REQUIRED_VERSION=1.7

echo "Checking git version ..."
echo ""
echo "Required : $GIT_REQUIRED_VERSION"

GIT_VERSION=$(git version | /usr/bin/perl -pe 's/.*?(\d+\.\d+).*/$1/')
echo "Version  : $GIT_VERSION"
echo ""

if [ -z "$GIT_VERSION" ]; then
	echo "Unable to detect git version"
	echo "Canceling installation ..."
	echo ""
	exit 1
fi

GIT_VERSION_OK=$(echo "$GIT_VERSION >= $GIT_REQUIRED_VERSION" | bc)
if [ "$GIT_VERSION_OK" = "0" ]; then
	echo "You need at least git version $GIT_REQUIRED_VERSION !"
	echo "Canceling installation ..."
	echo ""
	exit 1
fi

cd "$(dirname "$0")"

export GRS_ROOT=$HOME/.grs
export GRS_ROOT_LIB=$GRS_ROOT/perl5
export GRS_ROOT_INSTALL=$GRS_ROOT/grs

export PERL_CPANM_OPT="--mirror-only --mirror http://cpan.celogeek.fr --mirror http://cpan.org -l $GRS_ROOT_LIB -L $GRS_ROOT_LIB -nq --self-contained"

set -e

rm -rf "$GRS_ROOT_INSTALL"
mkdir -p "$GRS_ROOT" "$GRS_ROOT_LIB" "$GRS_ROOT_INSTALL"

curl -sL http://cpanmin.us/ | /usr/bin/perl - App::local::lib::helper Redmine::API Moo MooX::Options LWP::Protocol::https Version::Next DateTime Term::ReadLine Date::Parse LWP::UserAgent List::MoreUtils List::Util List::Util::XS autodie utf8::all Term::Size Digest::MD5 Data::UUID JSON::XS URI::Escape IO::Interactive REST::Client URI DDP

cp -RvL share "$GRS_ROOT_INSTALL"
cp -av bin "$GRS_ROOT_INSTALL"

set +e

cat <<EOF

The installation of Git Redmine Suite is done.
Please add this to your bashrc file :

export PATH=\$HOME/.grs/grs/bin:\$PATH

EOF

if [ -n "$CURPWD" ] && [ -n "$1" ]
then
	echo ""
	echo "Move to $CURPWD"
	cd "$CURPWD"
	echo ""
	echo "Run : $*"
	echo ""
	exec $*
fi
