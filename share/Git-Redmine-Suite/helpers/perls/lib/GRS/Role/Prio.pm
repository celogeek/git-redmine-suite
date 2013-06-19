package GRS::Role::Prio;
# ABSTRACT: Prio role
=head1 DESCRIPTION

Prio role

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'highest_prio_only' => (
	is => 'ro',
	doc => 'display highest priority only'
);

1;