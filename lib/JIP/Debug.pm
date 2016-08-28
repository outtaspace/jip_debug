package JIP::Debug;

use base qw(Exporter);

use 5.006;
use strict;
use warnings;
use English qw(-no_match_vars);
use Fcntl qw(LOCK_EX LOCK_UN);
use Data::Dumper qw(Dumper);
use Carp qw(croak);

our $VERSION   = '0.01';
our @EXPORT_OK = qw(to_debug to_debug_raw);

our $COLOR = 'bright_yellow';

our $MSG_DELIMITER = q{=} x 80 . qq{\n\n};

our $DUMPER_INDENT   = 1;
our $DUMPER_DEEPCOPY = 1;

our $HANDLE = \*STDERR;

our $MAYBE_COLORED = sub { $ARG[0] };
eval {
    require Term::ANSIColor;
    $MAYBE_COLORED = sub { Term::ANSIColor::colored($ARG[0], $COLOR); };
};

our $MAKE_MSG_HEADER = sub {
    # $MAKE_MSG_HEADER=0, to_debug=1
    my ($package, undef, $line) = caller(1);

    # $MAKE_MSG_HEADER=0, to_debug=1, subroutine=2
    my (undef, undef, undef, $subroutine) = caller(2);

    my $text = join q{, }, (
        sprintf('package=%s', $package),
        (defined $subroutine ? sprintf('subroutine=%s',$subroutine) : ()),
        sprintf('line=%d', $line, ),
    );
    $text = qq{[$text]:};

    return $MAYBE_COLORED->($text);
};

# Supported on Perl 5.22+
eval {
    require Sub::Util;

    if (my $set_subname = Sub::Util->can('set_subname')) {
        $set_subname->('MAYBE_COLORED',   $MAYBE_COLORED);
        $set_subname->('MAKE_MSG_HEADER', $MAKE_MSG_HEADER);
    }

};

sub to_debug {
    my $msg_body = do {
        local $Data::Dumper::Indent   = $DUMPER_INDENT;
        local $Data::Dumper::Deepcopy = $DUMPER_DEEPCOPY;

        Dumper(\@_);
    };

    my $msg = sprintf qq{%s\n%s\n\n%s},
        $MAKE_MSG_HEADER->(),
        $msg_body,
        $MAYBE_COLORED->($MSG_DELIMITER);

    send_to_output($msg);
}

sub to_debug_raw {
    my $msg_text = shift;

    my $msg = sprintf qq{%s\n%s\n\n%s},
        $MAKE_MSG_HEADER->(),
        $msg_text,
        $MAYBE_COLORED->($MSG_DELIMITER);

    send_to_output($msg);
}

sub send_to_output {
    my $msg = shift;

    return unless $HANDLE;

    flock $HANDLE, LOCK_EX;
    $HANDLE->print($msg) or croak(sprintf q{Can't write to output: %s}, $OS_ERROR);
    flock $HANDLE, LOCK_UN;
}

1;

