package GRS::Role::Parent;

# ABSTRACT: Parent

=head1 DESCRIPTION

Role for parent

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'no_parent' => (
    is     => 'ro',
    doc    => 'Tasks without parent',
);
1;
