package GRS;

# ABSTRACT: GRS Main module

=head1 DESCRIPTION

Auto Import Role from import command and purpose command line

=cut

use strict;
use warnings;

# VERSION

use Moo;
use MooX::Options;

sub import {
    my ( $class, @extensions ) = @_;
    foreach my $ext ( map {"GRS::Role::$_"} @extensions ) {
        with $ext;
    }
}

1;
