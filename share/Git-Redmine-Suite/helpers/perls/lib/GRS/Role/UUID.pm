package GRS::Role::UUID;
# ABSTRACT: UUID params

# VERSION

use Moo::Role;
use MooX::Options;

option 'uuid' => (
  is => 'ro',
  doc => 'user uniq id',
  format => 's',
);

1;