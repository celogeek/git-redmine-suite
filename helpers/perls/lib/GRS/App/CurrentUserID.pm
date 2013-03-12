package GRS::App::CurrentUserID;
# ABSTRACT: Return the ID of the current user
=head1 DESCRIPTION

Retrieve the ID of the current user

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API';

sub server_suburl { '/users' }

sub app {
	my ($self) = @_;
	return $self->API->current->list->all()->content->{user}->{id};
}
1;