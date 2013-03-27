ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../"; pwd)
SCRIPT_DIR=$ROOT_DIR/helpers/scripts
PERL_DIR=$ROOT_DIR/helpers/perls
MAN_DIR=$ROOT_DIR/helpers/pod/guide

export PATH=$PERL_DIR/bin:$PATH
export PERL5LIB=$PERL_DIR/lib

source "$SCRIPT_DIR"/check_update.sh

source "$SCRIPT_DIR"/setup.sh
setup_upgrade

source "$SCRIPT_DIR"/guide.sh

if [ -z "$SETUP" ]; then
	source "$SCRIPT_DIR"/set_env.sh
	for P in "$SCRIPT_DIR"/grs/*.sh; do
		source "$P"
	done
fi