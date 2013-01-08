---
--- Shared Canvas simple schema
---

CREATE TABLE manifest (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  object_date VARCHAR(255) NOT NULL DEFAULT '',
  object_creator VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE sequence (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  updated_at DATETIME NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE manifest_sequence (
  id INTEGER NOT NULL PRIMARY KEY,
  manifest_id INTEGER NOT NULL,
  sequence_id INTEGER NOT NULL
);

CREATE TABLE canvas (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  height integer NOT NULL DEFAULT 0,
  width integer NOT NULL default 0
);

CREATE TABLE canvas_sequence (
  id INTEGER NOT NULL PRIMARY KEY ,
  canvas_id INTEGER NOT NULL,
  sequence_id INTEGER NOT NULL,
  position INTEGER NOT NULL
);

CREATE TABLE image_annotation (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  image_id INTEGER NOT NULL
);

CREATE TABLE canvas_image_annotation (
  id INTEGER NOT NULL PRIMARY KEY,
  canvas_id INTEGER NOT NULL,
  image_annotation_id INTEGER NOT NULL
);

CREATE TABLE zone (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  height INTEGER NOT NULL DEFAULT 0,
  width INTEGER NOT NULL DEFAULT 0,
  natural_angle FLOAT NOT NULL DEFAULT 0.0
);

CREATE TABLE zone_annotation (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  zone_id INTEGER NOT NULL
);

CREATE TABLE canvas_zone_annotation (
  id INTEGER NOT NULL PRIMARY KEY ,
  zone_annotation_id INTEGER NOT NULL,
  canvas_id INTEGER NOT NULL,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  w INTEGER NOT NULL,
  h INTEGER NOT NULL
);

CREATE TABLE layer (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE image_annotation_list_layer (
  id INTEGER NOT NULL PRIMARY KEY,
  image_annotation_list_id INTEGER NOT NULL,
  layer_id INTEGER NOT NULL
);

CREATE TABLE layer_text_annotation_list (
  id INTEGER NOT NULL PRIMARY KEY,
  text_annotation_list_id INTEGER NOT NULL,
  layer_id INTEGER NOT NULL
);

CREATE TABLE layer_manifest (
  id INTEGER NOT NULL PRIMARY KEY,
  layer_id INTEGER NOT NULL,
  manifest_id INTEGER NOT NULL
);

CREATE TABLE text_annotation_list (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE image_annotation_list (
  id INTEGER NOT NULL PRIMARY KEY ,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE text_annotation_text_annotation_list (
  id INTEGER NOT NULL PRIMARY KEY,
  text_annotation_id INTEGER NOT NULL,
  text_annotation_list_id INTEGER NOT NULL
);

CREATE TABLE image_annotation_image_annotation_list (
  id INTEGER NOT NULL PRIMARY KEY,
  image_annotation_id INTEGER NOT NULL,
  image_annotation_list_id INTEGER NOT NULL
);

CREATE TABLE image_annotation_list_manifest (
  id INTEGER NOT NULL PRIMARY KEY,
  image_annotation_list_id INTEGER NOT NULL,
  manifest_id INTEGER NOT NULL
);

CREATE TABLE image (
  id INTEGER NOT NULL PRIMARY KEY,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255),
  size INTEGER,
  width INTEGER,
  height INTEGER,
  format VARCHAR(64),
  url VARCHAR(255)
); 
