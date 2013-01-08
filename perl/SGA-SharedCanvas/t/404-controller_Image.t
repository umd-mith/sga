use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON;
use Image::Info qw(image_info);

BEGIN {
  $ENV{'CATALYST_CONFIG_LOCAL_SUFFIX'} = 'testing';
}

use lib './t/lib';
use t::REST;
use SGA::SharedCanvas::Controller::Image;

BEGIN {
  use_ok( 'Catalyst::Action::Deserialize::File' );
}

GET_ok( "/image", "Get list of images" );
GET_ok( "/image", "application/rdf", "Get list of images" );
GET_ok( "/image", "application/rdf+xml", "Get list of images" );

# upload root/static/images/catalyst_logo.png
my $image;
{ local $/ = undef;
  open my $fh, "<", "root/static/images/catalyst_logo.png";
  binmode $fh;
  $image = <$fh>;
  close $fh;
}

my $json = POST_image_ok( "/image", $image, "Add an image" );
my $img_info = image_info(\$image);

is $json->{width}, $img_info->{width}, "Right width";
is $json->{height}, $img_info->{height}, "Right height";
is $json->{format}, $img_info->{file_media_type}, "Right format";

my $img_url = $json->{_links}->{self};
is $json->{url}, $img_url, "Pointing to self since we uploaded media";

my $png = GET_ok( $img_url, "image/png", "Get PNG content" );

$json = POST_ok( "/image", {
  url => $img_url,
}, "Add another image with a url");

is $json -> {url}, $img_url, "Pointing to right image";
isnt $json->{_links}->{self}, $img_url, "self link pointing to right place";

done_testing();
