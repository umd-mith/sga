package SGA::SharedCanvas::Controller::Admin::Image;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Image;
use SGA::SharedCanvas::Resource::Image;
use LWP::UserAgent;
use Image::Info qw(image_info);

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/image') :CaptureArgs(0) { }

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {images} = [
    SGA::SharedCanvas::Collection::Image -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/content/images";
}

sub image_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::Image -> new(c => $c);
    my $params = $c -> request -> params;
    if($params->{url}) {
      my $url = $params -> {url};
      my $ua = LWP::UserAgent -> new;
      my $req = HTTP::Request->new(GET => $url);
      my $res = $ua->request($req);
      if($res -> is_success) {
        # see if we can get the image and find format, extents, etc.
        # format, height, width, size
        my $imgdata = $res -> decoded_content;
        my $info = image_info(\$imgdata);
        $params->{format} = $info->{file_media_type};
        $params->{width} = $info->{width};
        $params->{height} = $info->{height};
        $params->{size} = length($imgdata);
      }
      else {
        $c -> stash -> {form_data} = $c -> request -> params;
        $c -> stash -> {error_msg} = "Unable to retrieve image.";
        $c -> stash -> {invalid} = [ 'url' ];
        $c -> stash -> {missing} = [];
      }
    }
    if(!$c -> stash -> {error_msg}) {
      my $image = $self -> POST($c, $collection, $params);
      if($image) {
        $c -> response -> redirect($c->uri_for("/admin/image"));
      }
    }
  }
  $c -> stash -> {template} = "/admin/content/images/new";
}

1;

