package GRS::App::UUID;
# ABSTRACT: Generate an uuid

# VERSION

use Moo::Role;
use Data::UUID;

sub app {
  my ($self) = @_;


  return lc(substr(Data::UUID->new->create_hex(), 2));
}

1;