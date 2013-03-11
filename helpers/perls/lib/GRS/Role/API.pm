package GRS::Role::API;

# ABSTRACT: Redmine API

=head1 DESCRIPTION

Redmine API

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use Redmine::API;
use feature 'say';

option 'auth_key' => (
    is      => 'ro',
    format  => 's',
    default => sub { $ENV{REDMINE_AUTHKEY} },
    doc     => 'your auth key',
);

option 'server_url' => (
    is      => 'ro',
    format  => 's',
    default => sub { $ENV{REDMINE_URL} },
    doc     => 'the redmine url of the server',
);

option 'trace' => (
    is      => 'ro',
    doc     => 'trace mode',
    default => sub { !!$ENV{REDMINE_DEBUG} },
);

option 'server_suburl' => (
    is      => 'ro',
    default => sub {""},
    doc     => 'subpath',
    format  => 's',
);

has 'API' => ( is => 'lazy', );

sub _build_API {
    my ($self) = @_;
    my $r = Redmine::API->new(
        'auth_key' => $self->auth_key,
        'base_url' => $self->server_url . $self->server_suburl,
        'trace'    => $self->trace,
    );
}

sub BUILD {
    my ($self) = @_;
    my @missing_params = grep { !defined $self->$_ } qw/auth_key server_url/;
    if (@missing_params) {
        say "$_ is missing" for @missing_params;
        $self->options_usage;
        exit 1;
    }
}

1;
