use CatalystX::Declare;

view SGA::SharedCanvas::View::Mason
  extends Catalyst::View::Mason2 is mutable
{

  $CLASS -> config(
    plugins => [
      'HTMLFilters'
    ]
  );

}
