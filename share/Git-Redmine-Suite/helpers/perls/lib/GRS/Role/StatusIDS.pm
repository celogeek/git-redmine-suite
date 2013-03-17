package GRS::Role::StatusIDS;

# ABSTRACT: List of status

=head1 DESCRIPTION

List of status ids

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'status_ids' => (
    is     => 'ro',
    doc    => 'list of status ids',
    format => 'i@',
    autosplit => ',',
);
1;
