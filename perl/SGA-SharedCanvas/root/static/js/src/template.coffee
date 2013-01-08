sga.namespace 'template', (template) ->
  t = (s) -> 
    (d) -> _.template(s, d, {variable: 'data'})

  _.templateSettings =
    interpolate: /\{\{(.*?)\}\}/g
    escape: /\{\[(.*?)\]\}/g
    evaluate: /\[\[(.*?)\]\]/g

  template.namespace 'factsheet', (fs) ->
    fs.Manifest = t """
      <h2>{{ data.label[0] }}</h2>
      <p class='type'>Manifest</p>
      <p><a href="/m/{{ data.parent[0] }}">Play Manifest</a></p>
    """
    fs.Sequence = t """
      <h2>{{ data.label[0] }}</h2>
      <p class='type'>Sequence</p>
    """
    fs.Canvas = t """
      <h2>{{ data.label[0] }}</h2>
      <p class='type'>Canvas ({{ data.width[0] }} x {{ data.height[0] }})</p>
    """
