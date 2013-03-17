package GRS::Role::CFSet;
# ABSTRACT: cf set for a task
=head1 DESCRIPTION

CF set

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'cf_id' => (
		is => 'ro',
		doc => 'ID of the CF',
		format => 'i',
);

option 'cf_val' => (
		is => 'ro',
		doc => 'VAL of the CF',
		format => 's',
);

1;