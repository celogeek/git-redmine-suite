package GRS::Role::CFNames;
# ABSTRACT: CF Role
=head1 DESCRIPTION

CF Role

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'cf_names' => (
		is => 'ro',
		doc => 'Custom field names',
		format => 's',
		autosplit => ',',
);

1;