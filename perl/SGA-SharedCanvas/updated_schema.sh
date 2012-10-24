#! /bin/sh

rm -f sga.db
sqlite3 sga.db < schema.sql
./script/sga_sharedcanvas_create.pl model DB DBIC::Schema SGA::SharedCanvas::Schema \
  create=static dbi:SQLite:sga.db \
  on_connect_do="PRAGMA foreign_keys = ON"
