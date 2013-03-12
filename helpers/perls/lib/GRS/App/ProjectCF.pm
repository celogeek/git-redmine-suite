package GRS::App::ProjectCF;
# ABSTRACT: Return the Project CF ids
=head1 DESCRIPTION

Return the CF ids of a project

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::Project', 'GRS::Role::CFNames';

sub required_options { qw/server_url auth_key project cf_names/ }

sub app {
	my ($self) = @_;

	my $resp = $self->API->projects->project->get($self->project, include => 'custom_fields');
	my %cf = map { @$_{qw/name id/} } @{$resp->content->{project}->{custom_fields}};
	return map { $_ // "" } @cf{@{$self->cf_names}};
}
1;