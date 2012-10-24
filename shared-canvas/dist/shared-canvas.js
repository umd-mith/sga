// Generated by CoffeeScript 1.3.3

/*
# SGA Shared Canvas v0.0.1
#
# **SGA Shared Canvas** is a shared canvas reader written in CoffeeScript.
#
#  
# Date: Wed Oct 24 08:08:01 2012 -0400
#
# License TBD.
#
*/


(function() {
  var __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (function($, MITHGrid) {
    MITHGrid.globalNamespace("SGA");
    return SGA.namespace("Reader", function(SGAReader) {
      SGAReader.namespace("Data", function(Data) {
        Data.namespace("TextStore", function(TextStore) {
          return TextStore.initInstance = function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return MITHGrid.initInstance.apply(MITHGrid, __slice.call(args).concat([function(that) {
              var fileContents, loadingFiles, options, pendingFiles;
              options = that.options;
              fileContents = {};
              loadingFiles = {};
              pendingFiles = {};
              that.addFile = function(files) {
                var file, _i, _len, _results;
                if (!$.isArray(files)) {
                  files = [files];
                }
                _results = [];
                for (_i = 0, _len = files.length; _i < _len; _i++) {
                  file = files[_i];
                  _results.push((function(file) {
                    if ((fileContents[file] != null) || (loadingFiles[file] != null)) {
                      next;

                    }
                    loadingFiles[file] = [];
                    return $.ajax({
                      url: file,
                      type: 'GET',
                      processData: false,
                      success: function(data) {
                        var c, f, _j, _len1, _ref;
                        c = data.documentElement.textContent;
                        fileContents[file] = c;
                        _ref = loadingFiles[file];
                        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                          f = _ref[_j];
                          f(c);
                        }
                        return delete loadingFiles[file];
                      }
                    });
                  })(file));
                }
                return _results;
              };
              return that.withFile = function(file, cb) {
                if (fileContents[file] != null) {
                  return cb(fileContents[file]);
                } else if (loadingFiles[file] != null) {
                  return loadingFiles[file].push(cb);
                }
              };
            }]));
          };
        });
        return Data.namespace("Manifest", function(Manifest) {
          var NS;
          NS = {
            "http://dms.stanford.edu/ns/": "sc",
            "http://www.shared-canvas.org/ns/": "sc",
            "http://www.w3.org/2000/01/rdf-schema#": "rdfs",
            "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf",
            "http://www.w3.org/2003/12/exif/ns#": "exif",
            "http://purl.org/dc/elements/1.1/": "dc",
            "http://www.w3.org/ns/openannotation/core/": "oa",
            "http://www.openannotation.org/ns/": "oa",
            "http://www.w3.org/ns/openannotation/extension/": "oax",
            "http://www.openarchives.org/ore/terms/": "ore",
            "http://www.shelleygodwinarchive.org/ns/1#": "sga"
          };
          return Manifest.initInstance = function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return MITHGrid.initInstance.apply(MITHGrid, ["SGA.Reader.Data.Manifest"].concat(__slice.call(args), [function(that) {
              var data, importFromURL, itemsWithType, loadedUrls, options;
              options = that.options;
              data = MITHGrid.Data.Store.initInstance();
              loadedUrls = [];
              importFromURL = function(url, cb) {
                if (__indexOf.call(loadedUrls, url) >= 0) {
                  cb();
                  return;
                }
                loadedUrls.push(url);
                return $.ajax({
                  url: url,
                  type: 'GET',
                  contentType: 'application/rdf+json',
                  processData: false,
                  dataType: 'json',
                  success: function(data) {
                    return that.importJSON(data, cb);
                  },
                  error: cb
                });
              };
              that.importJSON = function(json, cb) {
                var item, items, ns, o, os, p, pname, prefix, ps, s, syncer, url, values, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1;
                syncer = MITHGrid.initSynchronizer(cb);
                items = [];
                for (s in json) {
                  ps = json[s];
                  item = {
                    id: s
                  };
                  for (p in ps) {
                    os = ps[p];
                    values = [];
                    if (p === "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
                      for (_i = 0, _len = os.length; _i < _len; _i++) {
                        o = os[_i];
                        if (o.type === "uri") {
                          for (ns in NS) {
                            prefix = NS[ns];
                            if (prefix === "sc" || prefix === "sga" || prefix === "oa" || prefix === "oax") {
                              if (o.value.slice(0, ns.length) === ns) {
                                values.push(prefix + o.value.substr(ns.length));
                              }
                            }
                          }
                        }
                      }
                      item.type = values;
                    } else {
                      for (_j = 0, _len1 = os.length; _j < _len1; _j++) {
                        o = os[_j];
                        if (o.type === "literal") {
                          values.push(o.value);
                        } else if (o.type === "uri") {
                          if (o.value.substr(0, 1) === "(" && o.value.substr(-1) === ")") {
                            values.push("_:" + o.value.substr(1, o.value.length - 2));
                          } else {
                            values.push(o.value);
                          }
                        } else if (o.type === "bnode") {
                          if (o.value.substr(0, 1) === "(" && o.value.substr(-1) === ")") {
                            values.push("_:" + o.value.substr(1, o.value.length - 2));
                          } else {
                            values.push(o.value);
                          }
                        }
                      }
                      if (values.length > 0) {
                        for (ns in NS) {
                          prefix = NS[ns];
                          if (p.substr(0, ns.length) === ns) {
                            pname = prefix + p.substr(ns.length);
                            item[pname] = values;
                          }
                        }
                      }
                    }
                  }
                  if (!(item.type != null) || item.type.length === 0) {
                    item.type = 'Blank';
                  }
                  if (((_ref = item.oreisDescribedBy) != null ? _ref.length : void 0) > 0) {
                    _ref1 = item.oreisDescribedBy;
                    for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                      url = _ref1[_k];
                      syncer.increment();
                      importFromURL(url, syncer.decrement);
                    }
                  } else {
                    items.push(item);
                  }
                }
                for (_l = 0, _len3 = items.length; _l < _len3; _l++) {
                  item = items[_l];
                  if (data.contains(item.id)) {
                    data.updateItems([item]);
                  } else {
                    data.loadItems([item]);
                  }
                }
                return syncer.done();
              };
              itemsWithType = function(type) {
                var types;
                if (!$.isArray(type)) {
                  type = [type];
                }
                types = MITHGrid.Data.Set.initInstance(type);
                return data.getSubjectsUnion(types, "type").items();
              };
              that.getCanvases = function() {
                return itemsWithType('scCanvas');
              };
              that.getSequences = function() {
                return itemsWithType('scSequence');
              };
              that.getAnnotations = function() {
                return itemsWithType('oaAnnotation');
              };
              that.getItem = data.getItem;
              that.contains = data.contains;
              return that.importFromURL = function(url, cb) {
                return importFromURL(url, function() {
                  if (cb != null) {
                    return cb();
                  }
                });
              };
            }]));
          };
        });
      });
      SGAReader.namespace("Presentation", function(Presentation) {
        return Presentation.namespace("Canvas", function(Canvas) {
          return Canvas.initInstance = function() {
            var args, _ref;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return (_ref = MITHGrid.Presentation).initInstance.apply(_ref, ["SGA.Reader.Presentation.Canvas"].concat(__slice.call(args), [function(that, container) {
              var SVG, SVGHeight, SVGWidth, canvasHeight, canvasWidth, dataView, options, pendingSVGfctns, svgRoot, svgRootEl;
              options = that.options;
              pendingSVGfctns = [];
              SVG = function(cb) {
                return pendingSVGfctns.push(cb);
              };
              svgRootEl = $("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"\n     xmlns:xlink=\"http://www.w3.org/1999/xlink\"\n     width=\"0\" height=\"0\" viewbG\n >\n</svg>");
              container.append(svgRootEl);
              svgRoot = $(svgRootEl).svg({
                onLoad: function(svg) {
                  var cb, _i, _len;
                  SVG = function(cb) {
                    return cb(svg);
                  };
                  for (_i = 0, _len = pendingSVGfctns.length; _i < _len; _i++) {
                    cb = pendingSVGfctns[_i];
                    cb(svg);
                  }
                  return pendingSVGfctns = null;
                }
              });
              canvasWidth = null;
              canvasHeight = null;
              SVGWidth = $(container).width() * 19 / 20;
              SVGHeight = null;
              MITHGrid.events.onWindowResize.addListener(function() {
                SVGWidth = $(container).width() * 19 / 20;
                if (canvasWidth != null) {
                  return that.setScale(SVGWidth / canvasWidth);
                }
              });
              that.events.onScaleChange.addListener(function(s) {
                if ((canvasWidth != null) && (canvasHeight != null)) {
                  SVGHeight = canvasHeight * s;
                  return SVG(function(svgRoot) {
                    svgRootEl.attr({
                      width: SVGWidth,
                      height: SVGHeight,
                      viewbox: "0 0 " + SVGWidth + " " + SVGHeight
                    });
                    return svgRootEl.css({
                      width: SVGWidth,
                      height: SVGHeight,
                      border: "0.5em solid #eeeeee",
                      "border-radius": "5px"
                    });
                  });
                }
              });
              dataView = MITHGrid.Data.SubSet.initInstance({
                dataStore: options.dataView,
                expressions: ['!target'],
                key: null
              });
              that.events.onCanvasChange.addListener(function(canvas) {
                var item, _ref, _ref1;
                dataView.setKey(canvas);
                item = dataView.getItem(canvas);
                canvasWidth = ((_ref = item.width) != null ? _ref[0] : void 0) || 1;
                canvasHeight = ((_ref1 = item.height) != null ? _ref1[0] : void 0) || 1;
                return that.setScale(SVGWidth / canvasWidth);
              });
              that.addLens('Image', function(container, view, model, id) {
                var item, rendering, svgImage;
                if (__indexOf.call(options.types || [], 'Image') < 0) {
                  return;
                }
                rendering = {};
                item = model.getItem(id);
                svgImage = null;
                SVG(function(svgRoot) {
                  var _ref;
                  return svgImage = svgRoot.image(0, 0, "100%", "100%", (_ref = item.image) != null ? _ref[0] : void 0, {
                    preserveAspectRatio: 'none'
                  });
                });
                rendering.update = function(item) {};
                rendering.remove = function() {
                  return SVG(function(svgRoot) {
                    return svgRoot.remove(svgImage);
                  });
                };
                return rendering;
              });
              return that.addLens('TextContent', function(container, view, model, id) {
                var app, highlightDS, item, mods, renderSVG, rendering, svgText, text;
                if (__indexOf.call(options.types || [], 'Text') < 0) {
                  return;
                }
                rendering = {};
                app = options.application();
                item = model.getItem(id);
                svgText = null;
                highlightDS = MITHGrid.Data.RangePager.initInstance({
                  dataStore: MITHGrid.Data.View.initInstance({
                    dataStore: model,
                    type: ['LineAnnotation', 'DeleteAnnotation', 'AddAnnotation']
                  }),
                  leftExpressions: ['.end'],
                  rightExpressions: ['.start']
                });
                highlightDS.events.onModelChange.addListener(function(m, ids) {
                  return console.log("Highlights changed: ", ids);
                });
                text = "";
                mods = {};
                renderSVG = function() {};
                SVG(function(svgRoot) {
                  var setMod, texts;
                  texts = svgRoot.createText();
                  setMod = function(pos, pref, type) {
                    if ($.isArray(pos)) {
                      pos = pos[0];
                    }
                    if (mods[pos] == null) {
                      mods[pos] = [];
                    }
                    if ($.isArray(type)) {
                      type = type[0];
                    }
                    return mods[pos].push({
                      action: pref,
                      type: type
                    });
                  };
                  return app.withSource(item.source[0], function(content) {
                    text = content.substr(item.start[0], item.end[0]);
                    highlightDS.setKeyRange(item.start[0], item.end[0]);
                    highlightDS.visit(function(id) {
                      var hitem;
                      hitem = highlightDS.getItem(id);
                      setMod(hitem.start, 'start', hitem.type);
                      return setMod(hitem.start, 'end', hitem.type);
                    });
                    return svgText = svgRoot.text(0, 100, text, {
                      "font-size": "12pt"
                    });
                  });
                });
                rendering.update = function(item) {};
                rendering.remove = function() {
                  return SVG(function(svgRoot) {
                    return svgRoot.remove(svgText);
                  });
                };
                return rendering;
              });
            }]));
          };
        });
      });
      SGAReader.namespace("Component", function(Component) {
        return Component.namespace("SequenceSelector", function(SequenceSelector) {
          return SequenceSelector.initInstance = function() {
            var args, _ref;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return (_ref = MITHGrid.Presentation).initInstance.apply(_ref, ["SGA.Reader.Component.SequenceSelector"].concat(__slice.call(args), [function(that, container) {
              var options;
              options = that.options;
              that.addLens('Sequence', function(container, view, model, id) {
                var el, item, rendering, _ref;
                rendering = {};
                item = model.getItem(id);
                el = $("<option></option>");
                el.attr({
                  value: id
                });
                el.text((_ref = item.label) != null ? _ref[0] : void 0);
                return $(container).append(el);
              });
              $(container).change(function() {
                return that.setSequence($(container).val());
              });
              return that.finishDisplayUpdate = function() {
                return that.setSequence($(container).val());
              };
            }]));
          };
        });
      });
      return SGAReader.namespace("Application", function(Application) {
        return Application.namespace("SharedCanvas", function(SharedCanvas) {
          SharedCanvas.initInstance = function() {
            var args, _ref;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return (_ref = MITHGrid.Application).initInstance.apply(_ref, ["SGA.Reader.Application.SharedCanvas"].concat(__slice.call(args), [function(that) {
              var currentSequence, manifestData, options, presentations, textSource;
              options = that.options;
              presentations = [];
              manifestData = SGA.Reader.Data.Manifest.initInstance();
              textSource = SGA.Reader.Data.TextStore.initInstance();
              that.withSource = function(file, cb) {
                return textSource.withFile(file, cb);
              };
              that.addPresentation = function(config) {
                var p;
                p = SGA.Reader.Presentation.Canvas.initInstance(config.container, {
                  types: config.types,
                  application: function() {
                    return that;
                  },
                  dataView: that.dataView.canvasAnnotations
                });
                return presentations.push([p, config.container]);
              };
              currentSequence = null;
              that.events.onSequenceChange.addListener(function(s) {
                var p, seq;
                currentSequence = s;
                seq = that.dataStore.data.getItem(currentSequence);
                p = seq.sequence.indexOf(that.getCanvas());
                if (p < 0) {
                  p = 0;
                }
                return that.setPosition(p);
              });
              that.events.onPositionChange.addListener(function(p) {
                var canvasKey, seq, _ref;
                seq = that.dataStore.data.getItem(currentSequence);
                canvasKey = (_ref = seq.sequence) != null ? _ref[p] : void 0;
                return that.setCanvas(canvasKey);
              });
              that.events.onCanvasChange.addListener(function(k) {
                var p, pp, seq, _i, _len, _results;
                that.dataView.canvasAnnotations.setKey(k);
                seq = that.dataStore.data.getItem(currentSequence);
                p = seq.sequence.indexOf(k);
                if (p >= 0 && p !== that.getPosition()) {
                  that.setPosition(p);
                }
                _results = [];
                for (_i = 0, _len = presentations.length; _i < _len; _i++) {
                  pp = presentations[_i];
                  _results.push(pp[0].setCanvas(k));
                }
                return _results;
              });
              if (options.url != null) {
                return manifestData.importFromURL(options.url, function() {
                  var aitem, canvases, id, imgitem, item, items, mitem, seq, sitem, textItem, textSpan, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;
                  items = [];
                  canvases = manifestData.getCanvases();
                  for (_i = 0, _len = canvases.length; _i < _len; _i++) {
                    id = canvases[_i];
                    mitem = manifestData.getItem(id);
                    item = {
                      id: id,
                      type: 'Canvas',
                      width: parseInt((_ref = mitem.exifwidth) != null ? _ref[0] : void 0, 10),
                      height: parseInt((_ref1 = mitem.exifheight) != null ? _ref1[0] : void 0, 10),
                      label: mitem.dctitle || mitem.rdfslabel
                    };
                    items.push(item);
                  }
                  _ref2 = manifestData.getSequences();
                  for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
                    id = _ref2[_j];
                    sitem = manifestData.getItem(id);
                    item = {
                      id: id,
                      type: 'Sequence',
                      label: sitem.rdfslabel
                    };
                    seq = [];
                    while (manifestData.contains((_ref3 = sitem.rdffirst) != null ? _ref3[0] : void 0)) {
                      seq.push(sitem.rdffirst[0]);
                      sitem = manifestData.getItem(sitem.rdfrest[0]);
                    }
                    item.sequence = seq;
                    items.push(item);
                  }
                  _ref4 = manifestData.getAnnotations();
                  for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
                    id = _ref4[_k];
                    aitem = manifestData.getItem(id);
                    if (__indexOf.call(aitem.type, "scContentAnnotation") >= 0) {
                      textItem = manifestData.getItem(aitem.oahasBody);
                      if ($.isArray(textItem)) {
                        textItem = textItem[0];
                      }
                      textSpan = manifestData.getItem(textItem.oahasSelector);
                      if ($.isArray(textSpan)) {
                        textSpan = textSpan[0];
                      }
                      textSource.addFile(textItem.oahasSource);
                      items.push({
                        id: aitem.id,
                        target: aitem.oahasTarget,
                        type: "TextContent",
                        source: textItem.oahasSource,
                        start: parseInt(textSpan.oaxbegin[0], 10),
                        end: parseInt(textSpan.oaxend[0], 10)
                      });
                    }
                    if (__indexOf.call(aitem.type, "sgaLineAnnotation") >= 0) {
                      textItem = manifestData.getItem(aitem.oahasTarget);
                      if ($.isArray(textItem)) {
                        textItem = textItem[0];
                      }
                      textSpan = manifestData.getItem(textItem.oahasSelector);
                      if ($.isArray(textSpan)) {
                        textSpan = textSpan[0];
                      }
                      items.push({
                        id: aitem.id,
                        target: textItem.oahasSource,
                        start: parseInt(textSpan.oaxbegin[0], 10),
                        end: parseInt(textSpan.oaxend[0], 10),
                        type: "LineAnnotation"
                      });
                    }
                    if (__indexOf.call(aitem.type, "sgaDeletionAnnotation") >= 0) {
                      textItem = manifestData.getItem(aitem.oahasTarget);
                      if ($.isArray(textItem)) {
                        textItem = textItem[0];
                      }
                      textSpan = manifestData.getItem(textItem.oahasSelector);
                      if ($.isArray(textSpan)) {
                        textSpan = textSpan[0];
                      }
                      items.push({
                        id: aitem.id,
                        target: textItem.oahasSource,
                        start: parseInt(textSpan.oaxbegin[0], 10),
                        end: parseInt(textSpan.oaxend[0], 10),
                        type: "DeletionAnnotation"
                      });
                    }
                    if (__indexOf.call(aitem.type, "sgaAdditionAnnotation") >= 0) {
                      textItem = manifestData.getItem(aitem.oahasTarget);
                      if ($.isArray(textItem)) {
                        textItem = textItem[0];
                      }
                      textSpan = manifestData.getItem(textItem.oahasSelector);
                      if ($.isArray(textSpan)) {
                        textSpan = textSpan[0];
                      }
                      items.push({
                        id: aitem.id,
                        target: textItem.oahasSource,
                        start: parseInt(textSpan.oaxbegin[0], 10),
                        end: parseInt(textSpan.oaxend[0], 10),
                        type: "AdditionAnnotation"
                      });
                    }
                    if (__indexOf.call(aitem.type, "scImageAnnotation") >= 0) {
                      imgitem = manifestData.getItem(aitem.oahasBody);
                      if ($.isArray(imgitem)) {
                        imgitem = imgitem[0];
                      }
                      items.push({
                        id: aitem.id,
                        target: aitem.oahasTarget,
                        label: aitem.rdfslabel,
                        image: imgitem.oahasSource || aitem.oahasBody,
                        type: "Image"
                      });
                    }
                  }
                  return that.dataStore.data.loadItems(items);
                });
              }
            }]));
          };
          return SharedCanvas.builder = function(config) {
            var manifestCallbacks, that, _ref;
            that = {
              manifests: {}
            };
            manifestCallbacks = {};
            that.onManifest = function(url, cb) {
              var _ref;
              if (that.manifests[url] != null) {
                return that.manifests[url].ready(function() {
                  return cb(that.manifests[url]);
                });
              } else {
                if ((_ref = manifestCallbacks[url]) == null) {
                  manifestCallbacks[url] = [];
                }
                return manifestCallbacks[url].push(cb);
              }
            };
            that.addPresentation = function(el) {
              var manifest, manifestUrl, types, _ref;
              manifestUrl = $(el).data('manifest');
              if (manifestUrl != null) {
                manifest = that.manifests[manifestUrl];
                if (!(manifest != null)) {
                  manifest = Application.SharedCanvas.initInstance({
                    url: manifestUrl
                  });
                  that.manifests[manifestUrl] = manifest;
                  manifest.ready(function() {
                    var cb, cbs, _i, _len;
                    cbs = manifestCallbacks[manifestUrl] || [];
                    for (_i = 0, _len = cbs.length; _i < _len; _i++) {
                      cb = cbs[_i];
                      cb(manifest);
                    }
                    return delete manifestCallbacks[manifestUrl];
                  });
                }
                manifest.run();
                types = (_ref = $(el).data('types')) != null ? _ref.split(/\s*,\s*/) : void 0;
                return that.onManifest(manifestUrl, function(manifest) {
                  return manifest.addPresentation({
                    types: types,
                    container: $(el)
                  });
                });
              }
            };
            if ((_ref = config["class"]) == null) {
              config["class"] = ".canvas";
            }
            $(config["class"]).each(function(idx, el) {
              return that.addPresentation(el);
            });
            return that;
          };
        });
      });
    });
  })(jQuery, MITHGrid);

  MITHGrid.defaults('SGA.Reader.Application.SharedCanvas', {
    dataStores: {
      data: {
        types: {
          Sequence: {},
          Canvas: {}
        },
        properties: {
          target: {
            valueType: 'item'
          }
        }
      }
    },
    dataViews: {
      canvasAnnotations: {
        dataStore: 'data',
        type: MITHGrid.Data.SubSet,
        expressions: ['!target']
      },
      sequences: {
        dataStore: 'data',
        types: ['Sequence']
      }
    },
    variables: {
      Canvas: {
        is: 'rw'
      },
      Sequence: {
        is: 'rw'
      },
      Position: {
        is: 'rw'
      }
    }
  });

  MITHGrid.defaults('SGA.Reader.Component.SequenceSelector', {
    variables: {
      Sequence: {
        is: 'rw'
      }
    }
  });

  MITHGrid.defaults('SGA.Reader.Presentation.Canvas', {
    variables: {
      Canvas: {
        is: 'rw'
      },
      Scale: {
        is: 'rw'
      }
    }
  });

}).call(this);
