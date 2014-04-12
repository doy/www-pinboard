package WWW::Pinboard;
use Moose;

use HTTP::Tiny;
use JSON::PP;
use URI;

has token => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _endpoint => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'endpoint',
    default  => 'https://api.pinboard.in/v1/',
);

has endpoint => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $uri = URI->new($self->_endpoint);
        $uri->query_form(auth_token => $self->token, format => 'json');
        return $uri;
    },
);

has ua => (
    is      => 'ro',
    isa     => 'HTTP::Tiny',
    lazy    => 1,
    default => sub { HTTP::Tiny->new },
);

has json => (
    is      => 'ro',
    isa     => 'JSON::PP',
    lazy    => 1,
    default => sub { JSON::PP->new },
);

for my $method (qw(update add delete get recent dates all suggest)) {
    __PACKAGE__->meta->add_method($method => sub {
        my $self = shift;
        my (%args) = @_;

        my $progress = delete $args{progress};

        my $uri = $self->endpoint->clone;
        # XXX eventually support other parts of the api
        $uri->path($uri->path . 'posts/' . $method);
        $uri->query_form($uri->query_form, %args);

        my $res = $self->ua->get(
            $uri, { $progress ? (data_callback => $progress) : () }
        );
        die $res->{content} unless $res->{success};
        return $self->json->decode($res->{content});
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
