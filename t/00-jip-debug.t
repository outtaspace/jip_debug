#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);
use Capture::Tiny qw(capture capture_stderr);

BEGIN {
    eval 'use Test::Exception';
    plan skip_all => 'Test::Exception needed' if $EVAL_ERROR;
}

plan tests => 11;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::Debug', '0.999_002';
    require_ok 'JIP::Debug';

    diag(
        sprintf 'Testing JIP::Debug %s, Perl %s, %s',
            $JIP::Debug::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'Exportable functions' => sub {
    plan tests => 5;

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

    throws_ok { to_debug_count() } qr{
        Undefined \s subroutine \s &main::to_debug_count \s called
    }x;
};

subtest 'Exportable variables' => sub {
    plan tests => 10;

    no warnings qw(once);

    ok $JIP::Debug::COLOR           eq 'bright_green';
    ok $JIP::Debug::MSG_DELIMITER   eq q{-} x 80;
    ok $JIP::Debug::DUMPER_INDENT   == 1;
    ok $JIP::Debug::DUMPER_DEEPCOPY == 1;
    ok $JIP::Debug::DUMPER_SORTKEYS == 1;

    ok ref($JIP::Debug::HANDLE)          eq 'GLOB';
    ok ref($JIP::Debug::MAYBE_COLORED)   eq 'CODE';
    ok ref($JIP::Debug::MAKE_MSG_HEADER) eq 'CODE';

    is_deeply \%JIP::Debug::TRACE_PARAMS, {skip_frames => 1};

    is_deeply \%JIP::Debug::TRACE_AS_STRING_PARAMS, {};
};

subtest 'resolve_subroutine_name()' => sub {
    plan tests => 6;

    is JIP::Debug::resolve_subroutine_name(),                  undef;
    is JIP::Debug::resolve_subroutine_name(undef),             undef;
    is JIP::Debug::resolve_subroutine_name(q{}),               undef;
    is JIP::Debug::resolve_subroutine_name('subroutine_name'), undef;

    is JIP::Debug::resolve_subroutine_name('::subroutine_name'),                 'subroutine_name';
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
        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { return $ARG[0] };
        local $JIP::Debug::DUMPER_INDENT   = 0;

        JIP::Debug::to_debug(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        \$VAR1\s+=\s+\[42\];
        \n\n
        $
    }x;
};

subtest 'to_debug_raw()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { return $ARG[0] };

        JIP::Debug::to_debug_raw(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        42
        \n\n
        $
    }x;
};

subtest 'to_debug_empty()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { return $ARG[0] };

        JIP::Debug::to_debug_empty(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        \n{18}
        \n\n
        $
    }x;
};

subtest 'to_debug_count()' => sub {
    my @tests = (
        [q{<no \s label>}, 1],
        [q{<no \s label>}, 2],
        [q{<no \s label>}, 3, undef],
        [q{<no \s label>}, 4, q{}],
        [q{0}, 1, 0],
        [q{0}, 2, q{0}],
        [q{tratata}, 1, 'tratata'],
        [q{tratata}, 2, 'tratata'],
    );

    plan tests => scalar @tests;

    foreach my $test (@tests) {
        my ($label_regex, $count, @params) = @{ $test };

        my $stderr_listing = capture_stderr {
            local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
            local $JIP::Debug::MAYBE_COLORED   = sub { return $ARG[0] };

            JIP::Debug::to_debug_count(@params);
        };
        like $stderr_listing, qr{
            ^
            header
            \n
            $label_regex: \s $count
            \n\n
            $
        }x;
    }
};

subtest 'to_debug_count() with callback' => sub {
    plan tests => 1;

    # cleanup
    local %JIP::Debug::COUNT_OF_LABEL = (
        $JIP::Debug::NO_LABEL_KEY => 0,
    );

    my $sequence = [];
    my $cb = sub {
        my ($label, $count) = @ARG;

        push @{ $sequence }, [$label, $count];
    };

    my @tests = (
        [],
        ['tratata'],
        [$cb],
        ['tratata', $cb],
        [$cb],
        ['tratata', $cb],
        [],
        ['tratata'],
    );

    foreach my $test (@tests) {
        capture_stderr { JIP::Debug::to_debug_count(@{ $test }); };
    }

    is_deeply $sequence, [
        [q{<no label>}, 2],
        [q{tratata},    2],
        [q{<no label>}, 3],
        [q{tratata},    3],
    ];
};

subtest 'to_debug_trace()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
        local $JIP::Debug::MAYBE_COLORED   = sub { return $ARG[0] };

        JIP::Debug::to_debug_trace();
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        Trace \s begun \s at .* \s line \s \d+
        \n\n
        $
    }sx;
};

