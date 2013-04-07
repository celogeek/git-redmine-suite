package GRS::App::Piwik;

# ABSTRACT: Tracking GRS usage

# VERSION

use Moo::Role;
use MooX::Options;
use Term::Size 'chars';
use JSON::XS qw/encode_json/;
use URI::Escape;
use LWP::Curl;
use Config;

with 'GRS::Role::ServerURL', 'GRS::Role::UUID', 'GRS::Role::Version';

option 'piwik_url' => (
    is      => 'ro',
    format  => 's',
    default => sub {'https://stats.celogeek.fr/piwik.php'}
);

option 'action' => (
    is     => 'ro',
    format => 's',
);

option 'action_options' => (
    is     => 'ro',
    format => 's',
);

option 'lang' => (
    is      => 'ro',
    format  => 's',
    default => sub { substr( $ENV{LANG} // '', 0, 2 ) }
);

option 'git_version' => (
    is     => 'ro',
    format => 's',
);

sub params {
    my ($self) = @_;
    return (
        idsite      => 10,
        rec         => 1,
        url         => $self->server_url,
        action_name => $self->_clean_action,
        _id         => $self->uuid,
        rand        => int( 1_000_000_000 * rand() ),
        apiv        => 1,
        _cvar       => {
            "1" => [ GRS_VERSION  => $self->version ],
            "2" => [ GIT_VERSION  => $self->git_version ],
            "3" => [ PERL_VERSION => "".$^V ],
            "4" => [ LOCALE       => $ENV{LANG} // "" ],
            "5" => [ OS           => ($Config{'osname'} // "") . " " . ($Config{'osvers'} // "") ]
        },
        res => $self->_get_resolution,
        $self->_hms,
        lang => $self->lang,
    );
}

sub required_options {qw/server_url uuid action version git_version/}

sub app {
    my ($self) = @_;

    my $ua
        = 'GRS '
        . $self->version . ' ('
        . ( $Config{'osname'} // "" ) . ' v'
        . ( $Config{'osvers'} // "" ) . ')';

    my $lwp = LWP::Curl->new( user_agent => $ua, );

    $lwp->get( $self->piwik_url . '?' . $self->_encode_params );

    return;

}

sub _clean_action {
    my ($self) = @_;
    my $action = $self->action;
    $action =~ s/^git\-redmine\-//;
    $action =~ s/(.*?)(?:\-|$)/\u$1/g;

    my $action_options = $self->action_options;
    return $action if !defined $action_options;
    return $action . ' (' . $action_options . ')';
}

sub _get_resolution {
    my ($self) = @_;

    my ( $col, $row ) = chars;
    return '' if !defined $col || !defined $row;

    return join( 'x', $col, $row );
}

sub _hms {
    my @t = localtime;
    return h => $t[2], m => $t[1], s => $t[0];
}

sub _encode_params {
    my ($self) = @_;

    my %params = $self->params;

    my @res;
    for my $k ( keys %params ) {
        my $val = $params{$k};
        if ( ref $val ) {
            $val = encode_json($val);
        }
        push @res, join( '=', $k, uri_escape($val) );
    }

    return join( '&', @res );
}

1;
