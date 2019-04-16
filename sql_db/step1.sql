
---------------------------------------------------------------------------------------------
-- Tabelle Mautpunkte mit Multipoint Geometrien erzeugen
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.mautknoten;

CREATE TABLE IF NOT EXISTS import.mautknoten AS (
            SELECT * FROM import.mauttabelle
        );

ALTER TABLE import.mautknoten ADD COLUMN geom geometry(MultiPoint, 3857);
UPDATE import.mautknoten as m set geom = ST_COLLECT(ST_Transform(ST_SetSRID(ST_MakePoint(m.lon_von, m.lat_von), 4326),3857) , ST_Transform(ST_SetSRID(ST_MakePoint(m.lon_bis, m.lat_bis), 4326),3857));


CREATE INDEX idx_mautknoten_id ON import.mautknoten USING btree (id);
CREATE INDEX idx_mautknoten_abs_id ON import.mautknoten USING btree (abschnitt_id);
CREATE INDEX idx_mautknoten_geom ON import.mautknoten USING gist (geom);
ALTER TABLE import.mautknoten CLUSTER ON idx_mautknoten_id;
ALTER TABLE import.mautknoten CLUSTER ON idx_mautknoten_geom;

---------------------------------------------------------------------------------------------
-- Zwischenschritt Mautpunkte mit nur Autobahn:
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.mautpunkte_ab;



CREATE TABLE IF NOT EXISTS import.mautpunkte_ab AS (
with mp as (SELECT von as mautknotenname, ST_GEOMETRYN(geom, 1)::geometry(Point, 3857) as geom FROM import.mautknoten WHERE LEFT(strasse,1) = 'A' UNION SELECT bis as mautknotenname, ST_GEOMETRYN(geom, 2)::geometry(Point, 3857) as geom FROM import.mautknoten WHERE LEFT(strasse,1) = 'A' )
            SELECT
            ROW_NUMBER() OVER() mautpunkt_ab_id,
            mp.*
            FROM mp
        );
CREATE INDEX idx_mautpunkte_ab_id ON import.mautpunkte_ab USING btree (mautpunkt_ab_id);
CREATE INDEX idx_mautpunkte_ab_geom ON import.mautpunkte_ab USING gist (geom);

---------------------------------------------------------------------------------------------
-- Zwischenschritt Mautpunkte mit nur Bundesstraße:
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.mautpunkte_bs;



CREATE TABLE IF NOT EXISTS import.mautpunkte_bs AS (
with mp as (SELECT von as mautknotenname, ST_GEOMETRYN(geom, 1)::geometry(Point, 3857) as geom FROM import.mautknoten WHERE LEFT(strasse,1) = 'B' UNION SELECT bis as mautknotenname, ST_GEOMETRYN(geom, 2)::geometry(Point, 3857) as geom FROM import.mautknoten WHERE LEFT(strasse,1) = 'B' )
            SELECT
            ROW_NUMBER() OVER() mautpunkt_bs_id,
            mp.*
            FROM mp
        );
CREATE INDEX idx_mautpunkte_bs_id ON import.mautpunkte_bs USING btree (mautpunkt_bs_id);
CREATE INDEX idx_mautpunkte_bs_geom ON import.mautpunkte_bs USING gist (geom);

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