sga.namespace "util", (util) ->
  util.ajax = (config) ->
    ops =
      url: sga.config.url_base + config.url
      type: config.type
      contentType: 'application/json'
      processData: false
      dataType: 'json'
      success: config.success
      error: config.error

    if config.data?
      ops.data = JSON.stringify config.data

    $.ajax ops

  util.get  = (config) -> util.ajax $.extend({ type: 'GET' },  config)
  util.post = (config) -> util.ajax $.extend({ type: 'POST' }, config)
  util.put  = (config) -> util.ajax $.extend({ type: 'PUT' },  config)
  util.delete  = (config) -> util.ajax $.extend({ type: 'DELETE' }, config)

  util.success_message = (msg) ->
    div = $("""
      <div class='alert alert-success'>
        <a class='close' data-dismiss='alert' href='#'>&times;</a>
        <h4 class='alert-heading'>Success!</h4>
      </div>
    """);
    div.append(msg);
    $("#messages").append(div);
    setTimeout ->
      div.animate {
        opacity: 0
      }, 1000, ->
        div.remove()
    , 2000

  util.error_message = (msg) ->
    div = $("""
      <div class='alert alert-error'>
        <a class='close' data-dismiss='alert' href='#'>&times;</a>
        <h4 class='alert-heading'>Uh oh!</h4>
      </div>
    """);
    div.append(msg);
    $("#messages").append(div);
