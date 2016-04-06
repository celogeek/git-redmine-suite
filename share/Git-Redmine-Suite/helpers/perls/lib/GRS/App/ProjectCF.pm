package GRS::App::ProjectCF;
# ABSTRACT: Return the Project CF ids
=head1 DESCRIPTION

Return the CF ids of a project

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::CFFilter';

sub required_options { qw/server_url auth_key/ }

sub app {
  my ($self) = @_;

  my ($project) = $self->API_fetchAll('projects', { include => 'custom_fields' },
        undef, $self->can('cf_filter') );

  return if ! defined $project;

  my %cf = map { ( @$_{qw/name id/}) } @{$project->{custom_fields}};

  return (
    "git config redmine.git.repos " . $cf{GIT_REPOS},
    "git config redmine.git.pr " . $cf{GIT_PR},
    "git config redmine.git.release " . $cf{GIT_RELEASE},
  );

}
1;