package GRS::App::TaskCF;
# ABSTRACT: Return the Task CF values
=head1 DESCRIPTION

Return the CF values of a task

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::CFNames';

sub required_options { qw/server_url auth_key task_id cf_names/ }

sub app {
	my ($self) = @_;
	my $id = $self->task_id;
	my $resp = $self->API->issues->issue->get($id);
	my %cf = map { @$_{qw/name value/} } @{$resp->content->{issue}->{custom_fields}};
	return map { $_ // "" } @cf{@{$self->cf_names}};
}
1;