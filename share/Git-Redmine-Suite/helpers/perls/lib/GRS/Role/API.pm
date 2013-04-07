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

with 'GRS::Role::ServerURL';

option 'trace' => (
    is      => 'ro',
    doc     => 'trace mode',
    default => sub { !!$ENV{REDMINE_DEBUG} },
);

has 'server_suburl' => (
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

sub API_fetchAll {
    my ( $self, $what, $search, $progress, $filter ) = @_;

    my $offset = 0;
    my $total_count;
    my @res;
    my $loop = 0;
    $| = 1 if $progress;
    $search //= {};

    for ( ;; ) {
        my $resp = $self->API->$what->list->all(
            offset => $offset,
            %$search
        );
        my $content = $resp->content;
        $total_count //= $content->{total_count} // 0;

        if ( ref $filter eq 'CODE' ) {
            push @res, $self->$filter( @{ $content->{$what} } );
        }
        else {
            push @res, @{ $content->{$what} };
        }

        $offset += $content->{limit} // 0;
        last unless $offset < $total_count;
        $loop = 1;
        print $progress if $progress;
    }
    if ($progress) {
        print " " if $loop;
        say ": \n";
    }

    return @res;
}

1;
