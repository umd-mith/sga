package SGA::SharedCanvas::Resource::Sequence;
#<dc:format>application/rdf+xml</dc:format>
#<dcterms:creator rdf:resource="urn:uuid:13dc3da6-dabf-4659-89fa-ed7f535a1d20"/>
#<ore:describes rdf:resource="http://www.shared-canvas.org/impl/demo1/res/NormalSequence"/>

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Sequence';
rdf_type 'http://www.openarchives.org/ore/terms/ResourceMap';

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

prop updated_at => (
  is => 'ro',
  source => sub { $_[0] -> source -> updated_at -> iso8601 },
  rdf_type => 'literal',
  rdf_property => 'http://purl.org/dc/terms/modified',
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

has_many canvases => 'SGA::SharedCanvas::Resource::Canvas', (
  is => 'rw',
  ordered => 1, # results in particular RDF serialization
  source => sub { $_[0] -> source -> canvases },
  link_fragment => 'canvas',
);

1;
