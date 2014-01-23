# Shelley-Godwin Archive Search Framework

This is a Flask app for handling full-text and faceted search in SGA.

There currently are two routers:

* annotate: sends a query to solr and produces OA annotations of the highlights. This is used by the Shared Canvas viewer

* search: sends a query to solr and produces a simplified JSON object for display. This is used by the full-text search page