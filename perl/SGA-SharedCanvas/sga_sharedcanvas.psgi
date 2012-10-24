use strict;
use warnings;

use SGA::SharedCanvas;

my $app = SGA::SharedCanvas->apply_default_middlewares(SGA::SharedCanvas->psgi_app);
$app;

