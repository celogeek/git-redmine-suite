package GRS;

# ABSTRACT: GRS Main module

=head1 DESCRIPTION

Auto Import Role from import command and purpose command line

=cut

use strict;
use warnings;
use feature 'say';

# VERSION

use Moo;
use MooX::Options;

sub import {
    my ( $class, @extensions ) = @_;
    strict->import;
    warnings->import;
    feature->import('say');
    foreach my $ext ( map {"GRS::$_"} @extensions ) {
        with $ext;
    }
}

1;
