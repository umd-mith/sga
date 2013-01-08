#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
  $ENV{'CATALYST_CONFIG_LOCAL_SUFFIX'} = "testing";
}

use Catalyst::Test 'SGA::SharedCanvas';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
