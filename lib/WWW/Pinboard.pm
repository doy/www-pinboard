package WWW::Pinboard;
use Moose;
# ABSTRACT: https://pinboard.in/ API client

use HTTP::Tiny;
use JSON::PP;
use URI;

=head1 SYNOPSIS

  my $latest_post_sync_time = ...;
  my $api = WWW::Pinboard->new(token => $token);
  my $last_updated = $api->update->{update_time};
  if ($last_updated ge $latest_post_sync_time) {
      my @posts = @{ $api->all(fromdt => $latest_post_sync_time) };
      for my $post (@posts) {
          ...;
      }
  }

=head1 DESCRIPTION

This module is a basic client for the L<https://pinboard.in/> API. It currently
provides methods for each API method in the C<posts/> namespace (patches
welcome to add support for more methods). Each method takes a hash of
arguments, which correspond to the parameters documented in the API
documentation at L<https://pinboard.in/api/>. They can also take an additional
parameter C<progress>, which will be passed to the C<data_callback> parameter
of the call to C<get> on the L<HTTP::Tiny> object.

=cut

=attr token

Pinboard API token. You can access your API token at
L<https://pinboard.in/settings/password>.

=cut

has token => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr endpoint

URL of the API endpoint. Defaults to C<https://api.pinboard.in/v1/>.

=cut

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

=method update

=method add

=method delete

=method get

=method recent

=method dates

=method all

=method suggest

=cut

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

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/www-pinboard/issues>.

=head1 SEE ALSO

L<https://pinboard.in/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc WWW::Pinboard

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/WWW-Pinboard>

=item * Github

L<https://github.com/doy/www-pinboard>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pinboard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pinboard>

=back

=cut

1;
