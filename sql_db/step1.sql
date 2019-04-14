---------------------------------------------------------------------------------------------
-- 1. Analyseschritt OSM-Daten bereinigen
---------------------------------------------------------------------------------------------
-- Erstellung einer Tabelle, wo nur mautrelevante Straßen verwendet werden
-- Rampen werden für die Analyse nicht verwendet﻿
-- keine osm_links -> Datenfluss gering halten
---------------------------------------------------------------------------------------------

--- trunk motorway

DROP TABLE IF EXISTS import.motorway;

CREATE TABLE import.motorway AS
(SELECT
ROW_NUMBER() OVER() motorway_id,
  *
FROM
  import.osm_toll_roads
WHERE
 type = 'trunk' OR type = 'motorway'); 

ALTER TABLE import.motorway
  ADD CONSTRAINT motorway_id_pk PRIMARY KEY (motorway_id);

CREATE INDEX motorway_ID_idx ON import.motorway(motorway_id);

CREATE INDEX motorway_geom ON import.motorway  USING gist (geometry);

CREATE INDEX motorway_ref_idx
  ON import.motorway
  USING btree
  (ref);

CREATE INDEX motorway_osm_id_idx
  ON import.motorway
  USING btree
  (osm_id);

CREATE INDEX motorway_type_idx
  ON import.motorway
  USING btree
  (type);

ALTER TABLE import.motorway CLUSTER ON motorway_geom;
ALTER TABLE import.motorway CLUSTER ON motorway_id_pk;
ALTER TABLE import.motorway CLUSTER ON motorway_ID_idx;
ALTER TABLE import.motorway CLUSTER ON motorway_osm_id_idx;
ALTER TABLE import.motorway CLUSTER ON motorway_type_idx;
ALTER TABLE import.motorway CLUSTER ON motorway_ref_idx;



--- secondary primary


DROP TABLE IF EXISTS import.secondary;

CREATE TABLE import.secondary AS
(SELECT
ROW_NUMBER() OVER() secondary_id,
  *
FROM
  import.osm_toll_roads
WHERE
 type = 'secondary' OR type = 'primary' OR type = 'trunk');

ALTER TABLE import.secondary
  ADD CONSTRAINT secondary_id_pk PRIMARY KEY (secondary_id);

CREATE INDEX secondary_ID_idx ON import.secondary(secondary_id);

CREATE INDEX secondary_geom ON import.secondary  USING gist (geometry);

CREATE INDEX secondary_ref_idx
  ON import.secondary
  USING btree
  (ref);

CREATE INDEX secondary_osm_id_idx
  ON import.secondary
  USING btree
  (osm_id);

CREATE INDEX secondary_type_idx
  ON import.secondary
  USING btree
  (type);

ALTER TABLE import.secondary CLUSTER ON secondary_geom;
ALTER TABLE import.secondary CLUSTER ON secondary_id_pk;
ALTER TABLE import.secondary CLUSTER ON secondary_ID_idx;
ALTER TABLE import.secondary CLUSTER ON secondary_osm_id_idx;
ALTER TABLE import.secondary CLUSTER ON secondary_type_idx;
ALTER TABLE import.secondary CLUSTER ON secondary_ref_idx;