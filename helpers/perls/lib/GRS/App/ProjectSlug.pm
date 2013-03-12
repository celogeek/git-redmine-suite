package GRS::App::ProjectSlug;

# ABSTRACT: Return the list of project slug

=head1 DESCRIPTION

Return the list of project slug

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use feature 'say';
use List::MoreUtils qw/all/;

with 'GRS::Role::API';

sub required_options {qw/server_url auth_key/}

sub app {
    my ($self) = @_;

    my $filter = sub {
        my ( $self, @projects ) = @_;
        my @valid_projects;
        for my $project (@projects) {
            my %cf = map { ( $_->{name} => $_->{id} ) }
                @{ $project->{custom_fields} };
            push @valid_projects, $project
                if all {defined} @cf{qw/GIT_REPOS GIT_PR GIT_RELEASE/};
        }
        return @valid_projects;
    };

	print "List of all valid projects and slugs ";
    for my $project ( sort { $a->{identifier} cmp $b->{identifier} } $self->API_fetchAll('projects', {include => 'custom_fields'}, '.', $filter))
    {
        say sprintf( "    %-40s ( %s )", @$project{qw/identifier name/} );
    }

}
1;
