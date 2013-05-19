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

sub required_options {'version'}

sub app {
    my ($self) = @_;
    my $version = $self->version;

    my $content
        = LWP::Curl->new->get(
        'https://raw.github.com/celogeek/git-redmine-suite/master/Changes'
        );

    $content =~ s/^$version\s+.*//ms;

    return $content;
}
1;
