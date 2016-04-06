package GRS::Role::IDSOnly;
# ABSTRACT: Return only the ids
=head1 DESCRIPTION

Return only the ids

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'ids_only' => (
    is => 'ro',
    doc => 'Display only the IDS',
);
1;