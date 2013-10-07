###
#
# (c) Copyright University of Maryland 2012-2013.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

(($, MITHgrid) ->
  #
  # The application uses the SGA.Ranges namespace.
  #
  #
  MITHgrid.globalNamespace "SGA"
  SGA.namespace "Ranges", (SGAranges) ->

  	# # Data Managment
  	SGAranges.namespace "Data", (Data) ->

		  #
		  # ## Data.Manifest
		  #
		  Data.namespace "Manifest", (Manifest) ->

		    #
		    # We list all of the namespaces that we care about and the prefix
		    # we map them to. Some of the namespaces are easy "misspellings"
		    # that let us support older namespaces.
		    #
		    NS =
		      "http://dms.stanford.edu/ns/": "sc"
		      "http://www.shared-canvas.org/ns/": "sc"
		      "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
		      "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
		      "http://www.w3.org/2003/12/exif/ns#": "exif"
		      "http://purl.org/dc/elements/1.1/": "dc"
		      "http://www.w3.org/ns/openannotation/core/": "oa"
		      "http://www.openannotation.org/ns/": "oa"
		      "http://www.w3.org/ns/openannotation/extension/": "oax"
		      "http://www.openarchives.org/ore/terms/": "ore"
		      "http://www.shelleygodwinarchive.org/ns/1#": "sga"
		      "http://www.shelleygodwinarchive.org/ns1#": "sga"
		      "http://www.w3.org/2011/content#": "cnt"
		      "http://purl.org/dc/dcmitype/": "dctypes"

		    types =
		      "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": "item"
		      "http://www.w3.org/ns/openannotation/core/hasMotivation": "item"

		    Manifest.initInstance = (args...) ->
		      MITHgrid.initInstance "SGA.Ranges.Data.Manifest", args..., (that) ->
		        options = that.options

		        data = MITHgrid.Data.Store.initInstance()

		        that.size = -> data.size()
		        
		        importer = MITHgrid.Data.Importer.RDF_JSON.initInstance data, NS, types

		        loadedUrls = []

		        importFromURL = (url, cb) ->
		          if url in loadedUrls
		            cb()
		            return
		          loadedUrls.push url
		          
		          $.ajax
		            url: url
		            type: 'GET'
		            contentType: 'application/rdf+json'
		            processData: false
		            dataType: 'json'
		            success: (data) ->
		              that.importJSON data, cb
		            error: (e) -> 
		              throw new Error("Could not load the manifest")

		        # we want to get the rdf/JSON version of things if we can
		        that.importJSON = (json, cb) ->
		          # we care about certain namespaces - others we ignore
		          # those we care about, we translate for datastore
		          # {nsPrefix}{localName}
		          syncer = MITHgrid.initSynchronizer cb
		          syncer.increment()
		          importer.import json, (ids) ->
		            #
		            # If the manifest indicates that another document describes
		            # this resource, then we load the data before continuing
		            # processing for this resource.
		            #
		 
		            # we want anything that has the oreisDescribedBy property
		            idset = MITHgrid.Data.Set.initInstance ids
		            urls = data.getObjectsUnion(idset, 'oreisDescribedBy')
		            
		            urls.visit (url) ->
		              syncer.increment()
		              importFromURL url, syncer.decrement
		            syncer.decrement()
		          syncer.done()

		        itemsWithType = (type) ->
		          type = [ type ] if !$.isArray(type)
		          types = MITHgrid.Data.Set.initInstance type
		          data.getSubjectsUnion(types, "type").items()

		        itemsForCanvas = (canvas) ->
		          # Given a canvas, find the TEI XML URL
		          canvas = [ canvas ] if !$.isArray(canvas)
		          canvasSet = MITHgrid.Data.Set.initInstance(canvas)
		          specificResources = data.getSubjectsUnion(canvasSet, "oahasSource")
		          imageAnnotations = data.getSubjectsUnion(canvasSet, "oahasTarget")            
		          contentAnnotations = data.getSubjectsUnion(specificResources, "oahasTarget")
		          tei = data.getObjectsUnion(contentAnnotations, 'oahasBody')
		          teiURL = data.getObjectsUnion(tei, 'oahasSource')

		          # Now find all annotations targeting that XML URL
		          specificResourcesAnnos = data.getSubjectsUnion(teiURL, 'oahasSource')
		          annos = data.getSubjectsUnion(specificResourcesAnnos, 'oahasTarget').items()

		          # Append other annotations collected so far and return
		          return annos.concat imageAnnotations.items(), contentAnnotations.items()

		        flushSearchResults = ->
		          types = MITHgrid.Data.Set.initInstance ['sgaSearchAnnotation']
		          searchResults = data.getSubjectsUnion(types, "type").items()
		          data.removeItems searchResults

		        getSearchResultCanvases = ->
		          types = MITHgrid.Data.Set.initInstance ['sgaSearchAnnotation']
		          searchResults = data.getSubjectsUnion(types, "type")
		          specificResources = data.getObjectsUnion(searchResults, "oahasTarget") 
		          teiURL = data.getObjectsUnion(specificResources, 'oahasSource')

		          sources = data.getSubjectsUnion(teiURL, 'oahasSource')
		          
		          annos = data.getSubjectsUnion(sources, 'oahasBody')
		          step = data.getObjectsUnion(annos, 'oahasTarget')
		          canvasKeys = data.getObjectsUnion(step, 'oahasSource')

		          return $.unique(canvasKeys.items())


		        #
		        # Get things of different types. For example, "scCanvas" gets
		        # all of the canvas items.
		        #
		        that.getCanvases    = -> itemsWithType 'scCanvas'
		        that.getZones       = -> itemsWithType 'scZone'
		        that.getSequences   = -> itemsWithType 'scSequence'
		        that.getRanges      = -> itemsWithType 'scRange'
		        that.getAnnotations = -> itemsWithType 'oaAnnotation'
		        that.getAnnotationsForCanvas = itemsForCanvas
		        that.flushSearchResults = flushSearchResults
		        that.getSearchResultCanvases = getSearchResultCanvases

		        that.getItem = data.getItem
		        that.contains = data.contains

		        that.importFromURL = (url, cb) ->
		          importFromURL url, ->
		            cb() if cb?

      # # Presentations
			SGAranges.namespace "Presentation", (Presentation) ->
				Presentation.namespace "Range", (Range) ->
			    Range.initInstance = (args...) ->
			      MITHgrid.Presentation.initInstance "SGA.Ranges.Presentation.Range", args..., (that, container) ->
			        options = that.options

			        that.addLens 'Range', (container, view, model, id) ->
			        	rendering = {}
			        	console.log model.getItem id


			# # Components
			SGAranges.namespace "Component", (Component) ->
				0

			# # Controllers

			# # Core Utilities

			# # Application
			SGAranges.namespace "Application", (Application) ->

				#
				# ## Application.SGARangesApp
				#
				Application.namespace "SGARangesApp", (SGARangesApp) ->
					SGARangesApp.initInstance = (args...) ->
			      MITHgrid.Application.initInstance "SGA.Ranges.Application.SGARangesApp", args..., (that) ->
			        options = that.options

			        #
			        # ### Presentation Coordination
			        #

			        presentations = []

			        that.addPresentation = (config) ->
			          p = SGA.Ranges.Presentation.Range.initInstance config.container,
			            application: -> that
			            dataView: that.dataStore.data
			          presentations.push [ p, config.container ]

			        #
			        # ### Manifest Import
			        #

			        manifestData = SGA.Ranges.Data.Manifest.initInstance()

			        if options.url?
			          manifestData.importFromURL options.url, ->
			            items = []
			            syncer = MITHgrid.initSynchronizer()

			            canvases = manifestData.getCanvases()
			            syncer.process canvases, (id) ->
			              mitem = manifestData.getItem id
			              items.push
			                id: id
			                type: 'Canvas'
			                width: parseInt(mitem.exifwidth?[0], 10)
			                height: parseInt(mitem.exifheight?[0], 10)
			                label: mitem.dctitle || mitem.rdfslabel

			            seq = manifestData.getSequences()
			            syncer.process seq, (id) ->
			              sitem = manifestData.getItem id
			              item =
			                id: id
			                type: 'Sequence'
			                label: sitem.rdfslabel

			              seq = []
			              seq.push sitem.rdffirst[0]
			              sitem = manifestData.getItem sitem.rdfrest[0]
			              while sitem.id? # manifestData.contains(sitem.rdfrest?[0])
			                seq.push sitem.rdffirst[0]
			                sitem = manifestData.getItem sitem.rdfrest[0]
			              item.sequence = seq
			              items.push item

			            ranges = manifestData.getRanges()
			            syncer.process ranges, (id) ->
			            	ritem = manifestData.getItem id
			            	item =
			                id: id
			                type: 'Range'
			                label: ritem.rdfslabel

			              rng = []
			              rng.push ritem.rdffirst[0]
			              ritem = manifestData.getItem ritem.rdfrest[0]
			              while ritem.id?
			                rng.push ritem.rdffirst[0]
			                ritem = manifestData.getItem ritem.rdfrest[0]
			              item.sequence = rng
			              items.push item

			            syncer.done ->
			            	that.dataStore.data.loadItems items

			    SGARangesApp.builder = (config) ->
			    	that =
			        manifests: {}

			      manifestCallbacks = {}

			      that.onManifest = (url, cb) ->
			        if that.manifests[url]?
			          that.manifests[url].ready ->
			            cb that.manifests[url]
			        else
			          manifestCallbacks[url] ?= []
			          manifestCallbacks[url].push cb

			      that.addPresentation = (el) ->
			        manifestUrl = $(el).data('manifest')
			        if manifestUrl?
			          manifest = that.manifests[manifestUrl]

			          if !manifest?
			          	manifest = Application.SGARangesApp.initInstance
			              url: manifestUrl
			            that.manifests[manifestUrl] = manifest
			            manifest.ready -> 
			              cbs = manifestCallbacks[manifestUrl] || []
			              cb(manifest) for cb in cbs
			              delete manifestCallbacks[manifestUrl]

			          manifest.run()
			          that.onManifest manifestUrl, (manifest) ->
			            manifest.addPresentation
			              container: $(el)
			      
			      that.addPresentation $(config.class)
			      that


)(jQuery, MITHgrid)

MITHgrid.defaults 'SGA.Ranges.Application.SGARangesApp',
  dataStores:
    data:
      types:
        Sequence: {}
        Range: {}
        Canvas: {}
      properties:
        target:
          valueType: 'item'
  variables:
    Canvas:   { is: 'rw' }
    Sequence: { is: 'rw' }
    Position: { is: 'lrw', isa: 'numeric' }

# Work it, make it, do it, makes us
( ($) ->

	builder = SGA.Ranges.Application.SGARangesApp.builder
		class: ".range"

)(jQuery)