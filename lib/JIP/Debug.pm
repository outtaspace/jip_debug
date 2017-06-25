package JIP::Debug;

use base qw(Exporter);

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper qw(Dumper);
use Fcntl qw(LOCK_EX LOCK_UN);
use English qw(-no_match_vars);

our $VERSION   = '0.999_002';
our @EXPORT_OK = qw(to_debug to_debug_raw to_debug_empty);

our $HANDLE = \*STDERR;

our $MSG_FORMAT    = qq{%s\n%s\n%s\n%s\n\n};
our $MSG_DELIMITER = q{-} x 80;

our $DUMPER_INDENT   = 1;
our $DUMPER_DEEPCOPY = 1;
our $DUMPER_SORTKEYS = 1;

our $COLOR = 'bright_green';

our $MAYBE_COLORED = sub { $ARG[0] };
eval {
    require Term::ANSIColor;
    $MAYBE_COLORED = sub { Term::ANSIColor::colored($ARG[0], $COLOR); };
};

our $MAKE_MSG_HEADER = sub {
    # $MAKE_MSG_HEADER=0, to_debug=1
    my ($package, undef, $line) = caller(1);

    # $MAKE_MSG_HEADER=0, to_debug=1, subroutine=2
    my $subroutine = (caller(2))[3];

    $subroutine = _resolve_subroutine_name($subroutine);

    my $text = join q{, }, (
        sprintf('package=%s', $package),
        (defined $subroutine ? sprintf('subroutine=%s', $subroutine) : ()),
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
        local $Data::Dumper::Sortkeys = $DUMPER_SORTKEYS;

        Dumper(\@_);
    };

    my $msg_delimiter = defined $MSG_DELIMITER ? $MSG_DELIMITER : q{};
    $msg_delimiter = $MAYBE_COLORED->($msg_delimiter);

    my $msg = sprintf $MSG_FORMAT,
        $msg_delimiter,
        $MAKE_MSG_HEADER->(),
        $msg_delimiter,
        $msg_body;

    _send_to_output($msg);
}

sub to_debug_raw {
    my $msg_text = shift;

    my $msg_delimiter = defined $MSG_DELIMITER ? $MSG_DELIMITER : q{};
    $msg_delimiter = $MAYBE_COLORED->($msg_delimiter);

    my $msg = sprintf $MSG_FORMAT,
        $msg_delimiter,
        $MAKE_MSG_HEADER->(),
        $msg_delimiter,
        $msg_text;

    _send_to_output($msg);
}

sub to_debug_empty {
    my $msg_delimiter = defined $MSG_DELIMITER ? $MSG_DELIMITER : q{};
    $msg_delimiter = $MAYBE_COLORED->($msg_delimiter);

    my $msg = sprintf qq{%s\n%s%s},
        $msg_delimiter,
        $msg_delimiter,
        qq{\n} x 20;

    _send_to_output($msg);
}

sub _send_to_output {
    my $msg = shift;

    return unless $HANDLE;

    flock $HANDLE, LOCK_EX;
    $HANDLE->print($msg) or croak(sprintf q{Can't write to output: %s}, $OS_ERROR);
    flock $HANDLE, LOCK_UN;

    return 1;
}

sub _resolve_subroutine_name {
    my $subroutine = shift;

    return unless defined $subroutine;

    my ($subroutine_name) = $subroutine =~ m{::(\w+)$}x;

    return $subroutine_name;
}

1;

__END__

=head1 NAME

JIP::Debug - provides a convenient way to attach debug print statements anywhere in a program.

=head1 VERSION

Version 0.999_002

=head1 SYNOPSIS

    use JIP::Debug qw(to_debug to_debug_raw to_debug_empty);

    # The to_debug and to_debug_raw functions print messages to an output stream.

    # For complex data structures (references, arrays and hashes) you can use the
    to_debug(
        an_array    => [],
        a_hash      => {},
        a_reference => \42,
    );

    # Prints a string
    to_debug_raw('Hello');

    # Prints empty lines
    to_debug_empty();

=head1 SEE ALSO

Debug::Simple, Debuggit, Debug::Easy

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


