package GRS::App::ProjectUsers;

# ABSTRACT: Return the list of user for the project

=head1 DESCRIPTION

Return the list of user for the project

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::Project';

sub required_options {qw/server_url auth_key project/}

sub app {
    my ($self) = @_;

    my $resp = $self->API->projects->project->get( $self->project,
        include => 'members' );
    my $content = $resp->content->{project}->{members} // [];

    return
        map { [ @$_{qw/id name/} ] } sort { $a->{name} cmp $b->{name} } @$content;

}
1;
