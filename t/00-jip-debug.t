#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);
use Capture::Tiny qw(capture capture_stderr);

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 8;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::Debug', '0.01';
    require_ok 'JIP::Debug';

    diag(
        sprintf 'Testing JIP::Debug %s, Perl %s, %s',
            $JIP::Debug::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'Exportable functions' => sub {
    plan tests => 4;

    can_ok 'JIP::Debug', qw(to_debug to_debug_raw to_debug_empty);

    throws_ok { to_debug() } qr{
        Undefined \s subroutine \s &main::to_debug \s called
    }x;

    throws_ok { to_debug_raw() } qr{
        Undefined \s subroutine \s &main::to_debug_raw \s called
    }x;

    throws_ok { to_debug_empty() } qr{
        Undefined \s subroutine \s &main::to_debug_empty \s called
    }x;
};

subtest 'Exportable variables' => sub {
    plan tests => 7;

    no warnings qw(once);

    ok $JIP::Debug::COLOR           eq 'bright_green';
    ok $JIP::Debug::MSG_DELIMITER   eq q{-} x 80;
    ok $JIP::Debug::DUMPER_INDENT   eq 1;
    ok $JIP::Debug::DUMPER_DEEPCOPY eq 1;

    ok ref($JIP::Debug::HANDLE)          eq 'GLOB';
    ok ref($JIP::Debug::MAYBE_COLORED)   eq 'CODE';
    ok ref($JIP::Debug::MAKE_MSG_HEADER) eq 'CODE';
};

subtest '_resolve_subroutine_name()' => sub {
    plan tests => 5;

    is JIP::Debug::_resolve_subroutine_name(),                  undef;
    is JIP::Debug::_resolve_subroutine_name(undef),             undef;
    is JIP::Debug::_resolve_subroutine_name(q{}),               undef;
    is JIP::Debug::_resolve_subroutine_name('subroutine_name'), undef;

    is JIP::Debug::_resolve_subroutine_name('package::package::subroutine_name'), 'subroutine_name';
};

subtest '_send_to_output()' => sub {
    plan tests => 4;

    my ($stdout, $stderr) = capture {
        JIP::Debug::_send_to_output(42);
    };
    is $stderr, 42;
    is $stdout, q{};

    local $JIP::Debug::HANDLE = \*STDOUT;
    ($stdout, $stderr) = capture {
        JIP::Debug::_send_to_output(42);
    };
    is $stderr, q{};
    is $stdout, 42;
};

subtest 'to_debug()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { $ARG[0] };

        local $JIP::Debug::DUMPER_INDENT = 0;
        local $JIP::Debug::MSG_DELIMITER = 'delimiter';

        JIP::Debug::to_debug(42);
    };
    like $stderr_listing, qr{
        ^
        delimiter
        \n
        header
        \n
        delimiter
        \n
        \$VAR1\s+=\s+\[42\];
        \n\n
        $
    }x;
};

subtest 'to_debug_raw()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { $ARG[0] };

        local $JIP::Debug::DUMPER_INDENT = 0;
        local $JIP::Debug::MSG_DELIMITER = 'delimiter';

        JIP::Debug::to_debug_raw(42);
    };
    like $stderr_listing, qr{
        ^
        delimiter
        \n
        header
        \n
        delimiter
        \n
        42
        \n\n
        $
    }x;
};

subtest 'to_debug_empty()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { $ARG[0] };

        local $JIP::Debug::DUMPER_INDENT = 0;
        local $JIP::Debug::MSG_DELIMITER = 'delimiter';

        JIP::Debug::to_debug_empty(42);
    };
    like $stderr_listing, qr{
        ^
        delimiter
        \n
        delimiter
        \n{20}
        $
    }x;
};
