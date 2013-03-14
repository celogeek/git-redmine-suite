package GRS::Role::AssignedToID;

# ABSTRACT: Assigned to

=head1 DESCRIPTION

The user to assign

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'assigned_to_id' => (
    is     => 'ro',
    doc    => 'user to assign',
    format => 'i',
);
1;
