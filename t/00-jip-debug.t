#!/usr/bin/env perl

use lib 'lib'; # FIXME

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);
use Capture::Tiny qw(capture capture_stderr);

plan tests => 7;

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
    plan tests => 3;

    can_ok 'JIP::Debug', qw(to_debug to_debug_raw);

    eval { to_debug() } or do {
        like $EVAL_ERROR, qr{
            Undefined \s subroutine \s &main::to_debug \s called
        }x;
    };
    eval { to_debug_raw() } or do {
        like $EVAL_ERROR, qr{
            Undefined \s subroutine \s &main::to_debug_raw \s called
        }x;
    };
};

subtest 'Exportable variables' => sub {
    plan tests => 7;

    no warnings qw(once);

    ok $JIP::Debug::COLOR           eq 'bright_yellow';
    ok $JIP::Debug::MSG_DELIMITER   eq q{=} x 80 . qq{\n\n};
    ok $JIP::Debug::DUMPER_INDENT   eq 1;
    ok $JIP::Debug::DUMPER_DEEPCOPY eq 1;

    ok ref($JIP::Debug::HANDLE)          eq 'GLOB';
    ok ref($JIP::Debug::MAYBE_COLORED)   eq 'CODE';
    ok ref($JIP::Debug::MAKE_MSG_HEADER) eq 'CODE';
};

subtest 'resolve_subroutine_name()' => sub {
    plan tests => 5;

    is JIP::Debug::resolve_subroutine_name(),                  undef;
    is JIP::Debug::resolve_subroutine_name(undef),             undef;
    is JIP::Debug::resolve_subroutine_name(q{}),               undef;
    is JIP::Debug::resolve_subroutine_name('subroutine_name'), undef;

    is JIP::Debug::resolve_subroutine_name('package::package::subroutine_name'), 'subroutine_name';
};

subtest 'send_to_output()' => sub {
    plan tests => 4;

    my ($stdout, $stderr) = capture {
        JIP::Debug::send_to_output(42);
    };
    is $stderr, 42;
    is $stdout, q{};

    local $JIP::Debug::HANDLE = \*STDOUT;
    ($stdout, $stderr) = capture {
        JIP::Debug::send_to_output(42);
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
        header
        \n
        \$VAR1\s+=\s+\[42\];
        \n\n
        delimiter
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
        header
        \n
        42
        \n\n
        delimiter
        $
    }x;

};

