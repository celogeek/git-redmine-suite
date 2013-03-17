package GRS::App::ProjectCheckUsers;

# ABSTRACT: Check if a user own to a project

=head1 DESCRIPTION

Check if a user own to a project

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::Project', 'GRS::Role::AssignedToID';

sub required_options {qw/server_url auth_key project assigned_to_id/}

sub app {
    my ($self) = @_;

    my $resp = $self->API->projects->project->get( $self->project,
        include => 'members' );
    my $content = $resp->content->{project}->{members} // [];

    return
        grep { $_->{id} == $self->assigned_to_id } @$content;

}
1;
