ROOT_DIR=$(dirname "$(dirname "$(dirname ${BASH_SOURCE[0]})")")
SCRIPT_DIR=$ROOT_DIR/helpers/scripts
PERL_DIR=$ROOT_DIR/helpers/perls
MAN_DIR=$ROOT_DIR/helpers/pod/guide

export PATH=$PERL_DIR/bin:$PATH
export PERLLIB=$PERL_DIR/lib

set +e
source $SCRIPT_DIR/check_update.sh
set -e
source $SCRIPT_DIR/set_env.sh
source $SCRIPT_DIR/helpers.sh