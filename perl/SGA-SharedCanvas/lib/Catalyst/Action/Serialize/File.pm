package Catalyst::Action::Serialize::File;

use Moose;
use namespace::autoclean;
use Scalar::Util qw(openhandle);
use Image::Info qw(image_type);
use Imager;

extends 'Catalyst::Action';

# we want to accept the body and treat it as a file upload
# the file will be in the upload key
sub execute {
  my($self, $controller, $c) = @_;

  my $stash_key = (
    $controller -> {'serialize'} ?
      $controller->{'serialize'}->{'stash_key'} :
      $controller->{'stash_key'}
    ) || 'rest';

  if($c -> response -> status < 300) {
    my $output = $self -> serialize($c -> stash -> {$stash_key});
    $c -> response -> header('Content-Length', length($output));
    $c -> response -> output( $output );
  }
  else {
    $c -> response -> output( '' );
  }
  return 1;
}

sub serialize {
  my($self, $data) = @_;
  my $body = $data -> {file};
  if($body) {
    eval {
      if(openhandle $body) {
        seek($body, 0, 0);
      }
    };
    if($@) {
      return $@;
    }
    my $content;
    my $img_type = image_type($body)->{file_type};
    if($img_type ne $data->{type}) {
      my $img = Imager->new;
      $img -> read(fh => $body);
      my $type = $data->{type}; # mime type
      $type =~ s{^image/}{};
      $img -> write(data => \$content, type => $type);
    }
    else {
      local $\;
      $content = <$body>;
    }
    return $content;
  }
  return '';
}

__PACKAGE__ -> meta -> make_immutable;

1;
