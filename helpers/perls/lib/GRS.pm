package GRS;

# ABSTRACT: GRS Main module

=head1 DESCRIPTION

Auto Import Role from import command and purpose command line

=cut

use strict;
use warnings;
use feature 'say';
use utf8::all;

# VERSION

use Moo;
use MooX::Options;

sub import {
    my ( $class, @extensions ) = @_;
    strict->import;
    warnings->import;
    feature->import('say');
    utf8::all->import;
    foreach my $ext ( map {"GRS::App::$_"} @extensions ) {
        with $ext;
    }
}

sub run {
    my ($class, @params) = @_;
    my $self = $class->new_with_options;
    if ( $self->can('required_options') ) {
        my @missing_params
            = grep { !defined $self->$_ } $self->required_options;
        if (@missing_params) {
            say "$_ is missing" for @missing_params;
            $self->options_usage;
        }
    }
    return $self->app(@params);
}

1;
