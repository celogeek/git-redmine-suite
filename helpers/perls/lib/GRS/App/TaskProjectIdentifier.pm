package GRS::App::TaskProjectIdentifier;

# ABSTRACT: Retrieve the project identifier of a task

=head1 DESCRIPTION

Retrive the project identifier of a task

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID';

sub required_options {'task_id'}

use DDP colored => 1;

sub app {
    my ($self) = @_;

    my $id      = $self->task_id;
    my $resp    = $self->API->issues->issue->get($id);
    my $content = $resp->content->{issue};

    return $content->{project}->{identifier} // "";
}
1;
