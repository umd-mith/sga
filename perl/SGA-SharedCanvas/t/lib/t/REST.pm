package t::REST;

use Catalyst::Test 'SGA::SharedCanvas';

use Exporter;
use Test::More;
use JSON;

our @ISA = qw(Exporter);
our @EXPORT = qw(GET_ok GET_not_ok PUT_ok POST_ok DELETE_ok);

sub GET_ok {
  my $url = shift;
  my($media, $desc);

  if(@_ == 2) {
    $media = shift;
    $media .= '+json' unless $media =~ /\+/;
  }
  else {
    $media = 'application/json';
  }
  $desc = shift;

  diag "Content type of request: $media\n";

  my($res, $json);
  my $headers = HTTP::Headers -> new;

  $headers -> header('Accept' => $media);
  $headers -> header('Content-Type' => $media);

  ok( $res = request(
    HTTP::Request->new( GET => $url, $headers )
  ), "GET: $desc");

  ok( $res -> code < 300, "Status ok: $desc" );

  diag( $res -> content ) ; #if $res -> code >= 400;

  if($media =~ /json/) {
    eval { $json = decode_json($res -> content) };
    ok !$@, "Decode: $desc";
    return $json;
  }
  else {
    return $res -> content;
  }
}

sub GET_not_ok {
  my($url, $desc) = @_;

  my($res, $json);
  my $headers = HTTP::Headers -> new;

  $headers -> header('Accept' => 'application/json');
  $headers -> header('Content-Type' => 'application/json');

  $res = request(
    HTTP::Request->new( GET => $url, $headers )
  );

  ok( $res->code >= 400, "GET failed successfully: $desc" );
}

sub PUT_ok {
  my($url, $content, $desc) = @_;

  my($res, $json);
  if(ref $content) {
    $content = encode_json $content;
  }

  my $headers = HTTP::Headers -> new;

  $headers -> header('Accept' => 'application/json');
  $headers -> header('Content-Type' => 'application/json');

  ok( $res = request(
    HTTP::Request->new( PUT => $url, $headers, $content )
  ), "PUT: $desc");

  ok( $res -> code < 300, "Status ok: $desc" );

  eval { $json = decode_json($res -> content) };
  ok !$@, "Decode: $desc";
  return $json;
}

sub POST_ok {
  my($url, $content, $desc) = @_;

  my($res, $json);
  if(ref $content) {
    $content = encode_json $content;
  }

  my $headers = HTTP::Headers -> new;

  $headers -> header('Accept' => 'application/json');
  $headers -> header('Content-Type' => 'application/json');


  ok( $res = request(
    HTTP::Request->new( POST => $url, $headers, $content )
  ), "POST: $desc");

  ok( $res -> code < 300, "Status ok: $desc" );

  if($res -> code >= 400) {
    diag $res -> content;
  }

  eval { $json = decode_json($res -> content) };
  ok !$@, "Decode: $desc";
  return $json;
}

sub DELETE_ok {
  my($url, $desc) = @_;

  my $headers = HTTP::Headers -> new;

  $headers -> header('Accept' => 'application/json');
  $headers -> header('Content-Type' => 'application/json');

  # We add an empty JSON body to satisfy the deserializer in Catalyst
  my($res);
  ok( $res = request(
    HTTP::Request->new( DELETE => $url, $headers, "{}" )
  ), "DELETE: $desc");

  diag( $res -> content ) if $res -> code >= 400;
  ok( $res -> code < 300, "Status ok: $desc" );

}

1;
