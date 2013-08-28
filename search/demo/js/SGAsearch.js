// Generated by CoffeeScript 1.6.2
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.SGAsearch = {};

  (function($, SGAsearch, _, Backbone) {
    var _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;

    SGAsearch.SearchResult = (function(_super) {
      __extends(SearchResult, _super);

      function SearchResult() {
        _ref = SearchResult.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      SearchResult.prototype.defaults = {
        "hls": [],
        "id": "[Page]",
        "shelfmark": "[Shelfmark]",
        "title": "[Title]",
        "nbook": "[Notebook]",
        "author": "[Author]",
        "editor": "[Editor]",
        "date": "[Date]"
      };

      return SearchResult;

    })(Backbone.Model);
    SGAsearch.Facet = (function(_super) {
      __extends(Facet, _super);

      function Facet() {
        _ref1 = Facet.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      Facet.prototype.defaults = {
        "name": "",
        "num": 0
      };

      return Facet;

    })(Backbone.Model);
    SGAsearch.SearchResultList = (function(_super) {
      __extends(SearchResultList, _super);

      function SearchResultList() {
        _ref2 = SearchResultList.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      SearchResultList.prototype.model = SGAsearch.SearchResult;

      return SearchResultList;

    })(Backbone.Collection);
    SGAsearch.Facetlist = (function(_super) {
      __extends(Facetlist, _super);

      function Facetlist() {
        _ref3 = Facetlist.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      Facetlist.prototype.model = SGAsearch.Facet;

      return Facetlist;

    })(Backbone.Collection);
    SGAsearch.SearchResultListView = (function(_super) {
      __extends(SearchResultListView, _super);

      function SearchResultListView() {
        this.addOne = __bind(this.addOne, this);        _ref4 = SearchResultListView.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      SearchResultListView.prototype.target = null;

      SearchResultListView.prototype.render = function(dest) {
        this.target = dest;
        this.collection.each(this.addOne, this);
        return this;
      };

      SearchResultListView.prototype.addOne = function(model) {
        var view;

        view = new SGAsearch.SearchResultView({
          model: model
        });
        return $(this.target).append(view.render().$el);
      };

      SearchResultListView.prototype.clear = function() {
        return this.collection.each(function(m) {
          return m.trigger('destroy');
        });
      };

      return SearchResultListView;

    })(Backbone.View);
    SGAsearch.SearchResultView = (function(_super) {
      __extends(SearchResultView, _super);

      function SearchResultView() {
        _ref5 = SearchResultView.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      SearchResultView.prototype.template = _.template($('#result-template').html());

      SearchResultView.prototype.initialize = function() {
        this.listenTo(this.model, 'change', this.render);
        return this.listenTo(this.model, 'destroy', this.remove);
      };

      SearchResultView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this;
      };

      SearchResultView.prototype.remove = function() {
        this.$el.remove();
        return this;
      };

      return SearchResultView;

    })(Backbone.View);
    SGAsearch.FacetListView = (function(_super) {
      __extends(FacetListView, _super);

      function FacetListView() {
        this.addOne = __bind(this.addOne, this);        _ref6 = FacetListView.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      FacetListView.prototype.target = null;

      FacetListView.prototype.render = function(dest) {
        this.target = dest;
        this.collection.each(this.addOne, this);
        return this;
      };

      FacetListView.prototype.addOne = function(model) {
        var view;

        view = new SGAsearch.FacetView({
          model: model
        });
        return $(this.target).append(view.render().$el);
      };

      FacetListView.prototype.clear = function() {
        return this.collection.each(function(m) {
          return m.trigger('destroy');
        });
      };

      return FacetListView;

    })(Backbone.View);
    SGAsearch.FacetView = (function(_super) {
      __extends(FacetView, _super);

      function FacetView() {
        _ref7 = FacetView.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      FacetView.prototype.template = _.template($('#facet-template').html());

      FacetView.prototype.initialize = function() {
        this.listenTo(this.model, 'change', this.render);
        return this.listenTo(this.model, 'destroy', this.remove);
      };

      FacetView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this;
      };

      FacetView.prototype.remove = function() {
        this.$el.remove();
        return this;
      };

      return FacetView;

    })(Backbone.View);
    return SGAsearch.search = function(service, query, facets, destination, page) {
      var fields, updateResults, url,
        _this = this;

      if (page == null) {
        page = 0;
      }
      if (this.srlv != null) {
        this.srlv.clear();
      }
      this.srl = new SGAsearch.SearchResultList();
      this.srlv = new SGAsearch.SearchResultListView({
        collection: this.srl
      });
      fields = "text";
      url = "" + service + "?q=" + query + "&f=" + fields;
      updateResults = function(res) {
        var f_add, f_del, f_h_mws, f_h_pbs, f_nb, k, r, sr, v, _i, _len, _ref8, _ref9;

        $(".num-results .badge").show().text(res.numFound);
        _ref8 = res.results;
        for (_i = 0, _len = _ref8.length; _i < _len; _i++) {
          r = _ref8[_i];
          sr = new SGAsearch.SearchResult();
          _this.srlv.collection.add(sr);
          r.num = (res.results.indexOf(r) + 1) + page * 20;
          r.id = r.id.substr(r.id.length - 4);
          r.shelfmark = r.shelfmark.substr(r.shelfmark.length - 3);
          sr.set(r);
        }
        _this.srlv.render(destination);
        if (_this.nb_flv != null) {
          _this.nb_flv.clear();
        }
        _this.nb_fl = new SGAsearch.Facetlist();
        _this.nb_flv = new SGAsearch.FacetListView({
          collection: _this.nb_fl
        });
        _ref9 = res.facets.notebooks;
        for (k in _ref9) {
          v = _ref9[k];
          f_nb = new SGAsearch.Facet();
          _this.nb_flv.collection.add(f_nb);
          f_nb.set({
            "name": k,
            "num": v
          });
        }
        _this.nb_flv.render($(facets).find('#r-list-notebook'));
        if (_this.h_flv != null) {
          _this.h_flv.clear();
        }
        _this.h_fl = new SGAsearch.Facetlist();
        _this.h_flv = new SGAsearch.FacetListView({
          collection: _this.h_fl
        });
        f_h_mws = new SGAsearch.Facet();
        f_h_pbs = new SGAsearch.Facet();
        _this.h_flv.collection.add(f_h_mws);
        _this.h_flv.collection.add(f_h_pbs);
        f_h_mws.set({
          "name": "Mary Shelley",
          "num": res.facets.hand_mws
        });
        f_h_pbs.set({
          "name": "Percy Bysshe Shelley",
          "num": res.facets.hand_pbs
        });
        _this.h_flv.render($(facets).find('#r-list-hand'));
        if (_this.r_flv != null) {
          _this.r_flv.clear();
        }
        _this.r_fl = new SGAsearch.Facetlist();
        _this.r_flv = new SGAsearch.FacetListView({
          collection: _this.r_fl
        });
        f_add = new SGAsearch.Facet();
        f_del = new SGAsearch.Facet();
        _this.r_flv.collection.add(f_add);
        _this.r_flv.collection.add(f_del);
        f_add.set({
          "name": "Added Passages",
          "num": res.facets.added
        });
        f_del.set({
          "name": "Deleted Passages",
          "num": res.facets.deleted
        });
        return _this.r_flv.render($(facets).find('#r-list-rev'));
      };
      return $.ajax({
        url: url,
        type: 'GET',
        processData: false,
        success: updateResults
      });
    };
  })(jQuery, window.SGAsearch, _, Backbone);

}).call(this);
