package GRS::App::TaskInfo;

# ABSTRACT: Return task information

=head1 DESCRIPTION

Return task information

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use DateTime;
use Date::Parse;

with 'GRS::Role::API', 'GRS::Role::TaskID',
    'GRS::Role::ProjectFullName', 'GRS::Role::PrioColor';

sub required_options {qw/server_url auth_key task_id/}

option 'with_status'          => ( is => 'ro', );
option 'with_extended_status' => ( is => 'ro', );
option 'pad'                  => (
    is      => 'ro',
    default => sub {'    '},
    format  => 's',
    doc     => 'pad display',
);

sub app {
    my ($self) = @_;

    my $issue = $self->API->issues->issue->get( $self->task_id,
        include => 'custom_fields' )->content->{issue};

    my %cf = map { @$_{qw/name id/} } @{ $issue->{custom_fields} };
    return $self if grep { !exists $cf{$_} } qw/GIT_REPOS GIT_PR GIT_RELEASE/;

    return ( $self, $issue );

}

sub title {
    my ( $self, $issue ) = @_;
    return
          $issue->{tracker}->{name} . " #"
        . $self->task_id . " : "
        . $issue->{subject};
}

sub title_with_status {
    my ( $self, $issue ) = @_;

    my $duration_str = $self->_duration($issue);
    my $status       = $issue->{status}->{name};
    my $title        = $self->title($issue);
    my $release      = $self->_release($issue);
    my $released_str = "";
    if ($release) {
        $released_str = ", Released with v$release";
    }

    return "($status) $title, Updated $duration_str$released_str";
}

sub title_with_extended_status {
    my ( $self, $issue ) = @_;

    my %cf       = $self->_cf($issue);

    my $color = $self->prio_color->{lc($issue->{priority}->{name})} // 0;
    my $url = $self->server_url . "/issues/" . $issue->{id} ;
    my $description = $issue->{description};
    $description = "*" x length($url) . "\n\n" . $description if $description;
    my @response = (
        [ "Project"         => $self->project_fullname($issue->{project}->{id}) ],
        [ "Priority"        => "\033[".$color."m".$issue->{priority}->{name}."\033[0m" ],
        [ "Title"           => $self->title($issue) ],
        [ "Status"          => $issue->{status}->{name} ],
        [ "Last update"     => $self->_duration($issue) ],
        [ "Assigned to"     => $issue->{assigned_to}->{name} ],
        [ "Estimated hours" => $self->_hours($issue->{estimated_hours}) ],
        [ "Spent hours"     => $self->_hours($issue->{spent_hours})],
        [ "Reported Repos"  => $cf{GIT_REPOS} ],
        [ "Last PR"         => $cf{GIT_PR} ],
        [ "Released"        => $cf{GIT_RELEASE} ],
        [ "URL"             => $url ],
        [ "Description"     => $description],
    );
    return @response;
}

sub _cf {
    my ( $self, $issue ) = @_;
    my %cf = map { @$_{qw/name value/} } @{ $issue->{custom_fields} };
    return %cf;
}

sub _release {
    my ( $self, $issue ) = @_;
    my %cf = $self->_cf($issue);
    return $cf{GIT_RELEASE};
}

sub _duration {
    my ( $self, $issue ) = @_;

    my $now          = DateTime->now;
    my $duration_str = '???';
    eval {
        my $updated_on_str  = $issue->{updated_on};
        my $updated_on_time = str2time($updated_on_str);
        my $updated_on = DateTime->from_epoch( epoch => $updated_on_time );
        my %duration   = ( $now - $updated_on )->deltas;
        if ( $duration{month} ) {
            $duration_str = sprintf( '%d months and %d days ago',
                $duration{month}, $duration{days} );
        }
        elsif ( $duration{days} ) {
            $duration_str = sprintf( '%d days ago', $duration{days} );
        }
        else {
            $duration_str = 'today';
        }
    };

    return $duration_str;
}

sub _hours {
    my ($self, $hours) = @_;
    return unless defined $hours;
    return sprintf("%.02f", $hours);
}
1;
