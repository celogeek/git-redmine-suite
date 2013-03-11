package GRS::App::Changes;

# ABSTRACT: abstract

=head1 DESCRIPTION

description

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use LWP::Curl;

with 'GRS::Role::Version';

sub get_changes {
    my ($self) = @_;
    my $version = $self->version;

    my $content
        = LWP::Curl->new->get(
        'https://gitorious.celogeek.com/git/redmine-suite/blobs/raw/master/Changes'
        );

    $content =~ s/^$version\s+.*//ms;

    return $content;
}
1;
