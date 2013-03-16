package GRS::App::Question;

# ABSTRACT: Question Role

=head1 DESCRIPTION

Ask question

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use feature 'say';
use Carp;
use Term::ReadLine;

option 'question' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'The question to ask'
);

option 'answer_mode' => (
    is      => 'ro',
    format  => 's',
    default => sub {'yesno'},
    doc     => 'Type of question / answer : yesno / id',
);

option 'default_answer' => (
    is => 'ro',
    format => 's',
    doc => 'default answer'
);

sub app {
    my ($self) = @_;

    my $question = $self->question;
    my $term     = Term::ReadLine->new('Question');

    if ( $self->answer_mode eq 'yesno' ) {
        $self->answer_mode_yesno( $term, $question . ' (y/N) ' );
    }
    elsif ( $self->answer_mode eq 'id' ) {
        my $default_answer = $self->default_answer // "";
        $default_answer = "" if $default_answer !~ /^\d+$/;
        $question .= " ";
        $question .= "(default: $default_answer) " if length $default_answer;
        $self->answer_mode_id( $term, $question, $default_answer);
    }
    else {
        croak "Bad answer_mode !";
    }
}

sub answer_mode_yesno {
    my ( $self, $term, $prompt ) = @_;
    my $answer;
    say "";
    while ( defined( $answer = $term->readline($prompt) ) ) {
        $answer = lc($answer);
        next if $answer && $answer !~ /^[yn]$/;
        $answer = undef if ( $answer eq 'n' );
        last;
    }
    say "";
    exit !$answer;
}

sub answer_mode_id {
    my ( $self, $term, $prompt, $default_answer ) = @_;

    my $answer;
    say "";
    for ( ;; ) {
        $answer = $term->readline($prompt);
        $answer = $default_answer unless defined $answer && length $answer;
        last if defined $answer && $answer =~ /^\d+/;
    }
    print STDERR "\n";
    say $answer;
    exit 0;
}

1;
