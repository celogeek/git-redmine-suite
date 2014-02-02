package GRS::App::TaskProjectIdentifier;

# ABSTRACT: Retrieve the project identifier of a task

=head1 DESCRIPTION

Retrive the project identifier of a task

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID';

sub required_options { qw/server_url auth_key task_id/ }

sub app {
    my ($self) = @_;

    my $id      = $self->task_id;
    my $resp    = $self->API->issues->issue->get($id);
    my $content = $resp->{issue};

    return $content->{project}->{identifier} // "";
}
1;
