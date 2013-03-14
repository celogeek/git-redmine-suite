package GRS::App::ProjectCF;
# ABSTRACT: Return the Project CF ids
=head1 DESCRIPTION

Return the CF ids of a project

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use List::MoreUtils qw/all/;

with 'GRS::Role::API';

sub required_options { qw/server_url auth_key/ }

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

	my ($project) = $self->API_fetchAll('projects', { include => 'custom_fields' },
        undef, $filter );

	return if ! defined $project;

	my %cf = map { ( @$_{qw/name id/}) } @{$project->{custom_fields}};

	return (
		"git config redmine.git.repos " . $cf{GIT_REPOS},
		"git config redmine.git.pr " . $cf{GIT_PR},
		"git config redmine.git.release " . $cf{GIT_RELEASE},
	);

}
1;