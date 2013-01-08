use strict;
use warnings;
use Test::More;

BEGIN {
  $ENV{'CATALYST_CONFIG_LOCAL_SUFFIX'} = "testing";
}


BEGIN { use_ok 'SGA::SharedCanvas::Model::DB' }

done_testing();
