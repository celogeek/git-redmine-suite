package GRS::Role::ProjectFullName;

# ABSTRACT: Get full project name

=head1 DESCRIPTION

Get full project name

=cut

# VERSION

use Moo::Role;
use MooX::Options;

requires "API_fetchAll";

has "project_name" => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my @projects = $self->API_fetchAll('projects');
        my %project_name;
        for my $project (@projects) {
            $project_name{ $project->{id} } = {
                name   => $project->{name},
                parent => $project->{parent}->{id},
            };
        }
        return \%project_name;
    },
);

sub project_fullname {
    my ( $self, $id ) = @_;
    my $prjs      = $self->project_name;
    my @prj_names = $prjs->{$id}->{name};

    while ( $id = $prjs->{$id}->{parent} ) {
        my $name = $prjs->{$id}->{name};
        last if !defined $name;
        unshift @prj_names, $name;
    }

    return join ' / ', @prj_names;
}

1;
