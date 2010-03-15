package AnyEvent::Debounce;
use Moose;

use AnyEvent;

has 'delay' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);

has 'maximum_delays' => (
    is      => 'ro',
    isa     => 'Int',
    default => 4,
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

has '_delays' => (
    reader  => 'delays',
    traits  => ['Counter'],
    isa     => 'Int',
    default => 0,
    trigger => sub {
        my ($self, $new, $old) = @_;
        if ($new >= $self->maximum_delays){
            $self->send_events_now;
        }
    },
    handles => {
        'clear_delays' => 'reset',
        'record_delay' => 'inc',
    },
);

has '_timer' => (
    writer   => '_timer',
    clearer  => 'clear_timer',
);

sub reset_timer {
    my $self = shift;
    $self->_timer(
        AnyEvent->timer(
            after    => $self->delay,
            interval => 0,
            cb       => sub { $self->send_events_now },
        ),
    );
}

sub send_events_now {
    my $self = shift;
    $self->clear_timer;
    $self->clear_delays;
    my $events = $self->queued_events;
    $self->clear_queued_events;
    $self->cb->(@$events);
    return;
}

sub send {
    my ($self, @args) = @_;
    $self->queue_event([@args]);
    $self->reset_timer;
    $self->record_delay;
    return;
}

1;
