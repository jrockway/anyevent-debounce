use strict;
use warnings;
use Test::More;

use AnyEvent;
use AnyEvent::Debounce;

my $sent = 0;
my $done = AnyEvent->condvar;
my $d = AnyEvent::Debounce->new(
    delay => 2,
    cb    => sub { $done->send([@_]) },
);

my $sender; $sender = AnyEvent->timer( after => 0, interval => 0.1, cb => sub {
    $d->send($sent);
    undef $sender if ++$sent > 9;
});

my $result = $done->recv;

is $sent, 10, 'got 10 events before cb was called';
is_deeply $result, [map { [$_] } 0..9], 'got the events we expected';

done_testing;
