package GRS::App::PrioColor;

# ABSTRACT: Get prio color sample

=head1 DESCRIPTION

Get prio color sample


    Immediate=1;41:Urgent=1;31:High=1;37:Normal=37:Low=34

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use utf8::all;
use feature 'say';

with 'GRS::Role::API';

sub required_options {
    qw/server_url auth_key/;
}

sub server_suburl { '/enumerations' }

sub app {
    my ($self) = @_;

    my $color = {
        Immediate => '1;41',
        Urgent => '1;31',
        High => '1,37',
        Normal => '37',
        Low => '34',
    };

    my $resp = $self->API->issue_priorities->list->all();
    my @content = @{$resp->content->{issue_priorities}};

    my %res;
    my $default = 0;
    for my $c(@content[0..$#content-3]) {
        $default = 1 if $c->{is_default};
        my $current_color = $default ? 'Normal' : 'Low';
        $res{$c->{name}} = $color->{$current_color};
    }

    $res{$content[-3]->{name}} = $color->{'High'};
    $res{$content[-2]->{name}} = $color->{'Urgent'};
    $res{$content[-1]->{name}} = $color->{'Immediate'};

    return join(':', map { $_ . "=" . $res{$_} } keys %res);
}

1;
