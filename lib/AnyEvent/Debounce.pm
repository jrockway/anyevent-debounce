package AnyEvent::Debounce;
use Moose;

use AnyEvent;

has 'delay' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);

has 'cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has '_queued_events' => (
    traits   => ['Array'],
    reader   => 'queued_events',
    isa      => 'ArrayRef',
    default  => sub { [] },
    lazy     => 1,
    clearer  => 'clear_queued_events',
    handles  => { 'queue_event' => 'push' },
);

has 'timer' => (
    reader     => 'timer',
    lazy_build => 1,
);

sub _build_timer {
    my $self = shift;
    return AnyEvent->timer(
        after    => $self->delay,
        interval => 0,
        cb       => sub { $self->send_events_now },
    );
}

sub send_events_now {
    my $self = shift;
    my $events = $self->queued_events;
    $self->clear_timer;
    $self->clear_queued_events;
    $self->cb->(@$events);
    return;
}

sub send {
    my ($self, @args) = @_;
    $self->queue_event([@args]);
    $self->timer; # resets the timer if we don't have one
    return;
}

1;

__END__

=head1 NAME

AnyEvent::Debounce - wait a bit in case another event is received

=head1 SYNOPSIS

Create a debouncer:

   my $damper = AnyEvent::Debounce->new( cb => sub {
       my (@events) = @_;
       say "Got ", scalar @events, " event(s) in the batch";
       say "Got event with args: ", join ',', @$_ for @events;
   });

Send it events in rapid succession:

   $damper->send(1,2,3);
   $damper->send(2,3,4);

Watch the output:

   Got 2 events in the batch
   Got event with args: 1,2,3
   Got event with args: 2,3,4

Send it more evnts:

   $damper->send(1);
   sleep 5;
   $damper->send(2);

And notice that there was no need to "debounce" this time:

   Got 1 event in the batch
   Got event with args: 1

   Got 1 event in the batch
   Got event with args: 2

=head1 INITARGS

=head1 cb

The callback to be called when some events are ready to be handled.
Each "event" is an arrayref of the args passed to C<send>.

=head1 delay

The time to wait after receiving an event before sending it, in case
more events happen in the interim.

=head1 METHODS

=head1 send

Send an event; the handler will get everything you pass in.

=head1 REPOSITORY

L<http://github.com/jrockway/anyevent-debounce>

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

This module is free software.  You can redistribute it under the same
terms as perl itself.
