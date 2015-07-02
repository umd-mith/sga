( function ($) {
  var wl = new SGAranges.WorkList([
  //   {id: "ox-frankenstein-notebook_a",
  //   url: "/data/ox/ox-frankenstein-notebook_a/Manifest-index.jsonld",
  //   flat: true}
  // ,
  //   {id: "ox-frankenstein-notebook_b",
  //   url: "/data/ox/ox-frankenstein-notebook_b/Manifest-index.jsonld",
  //   flat: true}
  // ,
  //   {id: "ox-frankenstein-notebook_c1",
  //   url: "/data/ox/ox-frankenstein-notebook_c1/Manifest-index.jsonld",
  //   flat: true}
  // ,
  //   {id: "ox-frankenstein-notebook_c2",
  //   url: "/data/ox/ox-frankenstein-notebook_c2/Manifest-index.jsonld",
  //   flat: true}
  // ,
  //   {id: "ox-frankenstein-volume_i",
  //   url: "/data/ox/ox-frankenstein-volume_i/Manifest-index.jsonld",
  //   flat: false}
  // ,
  //   {id: "ox-frankenstein-volume_ii",
  //   url: "/data/ox/ox-frankenstein-volume_ii/Manifest-index.jsonld",
  //   flat: false}
  // ,
  //   {id: "ox-frankenstein-volume_iii",
  //   url: "/data/ox/ox-frankenstein-volume_iii/Manifest-index.jsonld",
  //   flat: false}
    {id: "pu_ii",
    url: "http://localhost:8000/demo/pu_ii.jsonld",
    flat: false}
  ]);

  var wlv = new SGAranges.WorkListView({"collection": wl});
  wlv.render("#ranges_wrapper");
})(jQuery)