---
--- Shared Canvas simple schema
---

CREATE TABLE manifest (
  id INTEGER PRIMARY KEY,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE sequence (
  id INTEGER PRIMARY KEY,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE TABLE manifest_sequence (
  manifest_id INTEGER NOT NULL,
  sequence_id INTEGER NOT NULL
);

CREATE TABLE canvas (
  id INTEGER PRIMARY KEY,
  uuid CHAR(20) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  height integer NOT NULL DEFAULT 0,
  width integer NOT NULL default 0
);

CREATE TABLE canvas_sequence (
  id INTEGER PRIMARY KEY,
  canvas_id INTEGER NOT NULL,
  sequence_id INTEGER NOT NULL,
  position INTEGER NOT NULL
);
