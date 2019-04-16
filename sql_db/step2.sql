---------------------------------------------------------------------------------------------
-- 1. Schritt:
--Linensegemente zusammenführen
-- Es werden die Anzahl der Intersektion der Liniensegmente erstellt, die nicht das gleiche id-Attribut besitzen
-- Dannach werden die Liniensegemente zusammengesetzt, die die gleiche Ref besitzen
-- Tabellenquelle: trunk_motorway
---------------------------------------------------------------------------------------------
--- trunk motorway motorway_link

DROP TABLE IF EXISTS import.line_intersections_motorway;

CREATE TABLE import.line_intersections_motorway AS
(
    SELECT
      ROW_NUMBER() OVER() line_intersections_motorway_id,
      a.osm_id,
      a.ref,
      a.geometry as geometry,
      COUNT(1) as count
    FROM
        import.motorway a
    JOIN
        import.motorway b ON
    ST_DWithin(a.geometry, b.geometry, 2)
    AND
    a.motorway_id != b.motorway_id
    GROUP BY
    a.osm_id,
    a.ref,
    a.geometry
);


CREATE INDEX line_intersections_motorway_id_idx
   ON import.line_intersections_motorway (line_intersections_motorway_id);

ALTER TABLE import.line_intersections_motorway CLUSTER ON line_intersections_motorway_id_idx;

--- secondary primary


DROP TABLE IF EXISTS import.line_intersections_secondary;

CREATE TABLE import.line_intersections_secondary AS
(
    SELECT
      ROW_NUMBER() OVER() line_intersections_secondary_id,
      a.osm_id,
      a.ref,
      a.geometry as geometry,
      COUNT(1) as count
    FROM
        import.secondary a
    JOIN
        import.secondary b ON
    
    ST_DWithin(a.geometry, b.geometry, 2)
    AND
    a.secondary_id != b.secondary_id
    GROUP BY
    a.osm_id,
    a.ref,
    a.geometry
);


CREATE INDEX line_intersections_secondary_id_idx
   ON import.line_intersections_secondary (line_intersections_secondary_id);

ALTER TABLE import.line_intersections_secondary CLUSTER ON line_intersections_secondary_id_idx;
---------------------------------------------------------------------------------------------
-- 2a. Schritt:
-- line_closestPoint Tabelle wird jetzt mit osm_Attributen verschnitten
-- Tabellenquelle: line_intersections
-- HINWEIS: postgres FEHLER:  Indexzeile benötigt 8504 Bytes, Maximalgröße ist 8191
---------------------------------------------------------------------------------------------

--- trunk motorway motorway_link

DROP TABLE IF EXISTS import.line_merge_motorway;

CREATE TABLE import.line_merge_motorway AS
(
  SELECT
  ROW_NUMBER() OVER() line_merge_motorway_id,
  i.ref,
  (ST_Dump(ST_LineMerge(ST_Multi(St_Collect(i.geometry))))).geom::geometry(linestring, 3857) AS geometry
  FROM
      import.line_intersections_motorway i
  Group BY
  i.ref
);

CREATE INDEX line_merge_motorway_id_idx
   ON import.line_merge_motorway (line_merge_motorway_id);

CREATE INDEX line_merge_motorway_ref_idx
   ON import.line_merge_motorway (ref);



CREATE INDEX line_merge_motorway_geom
   ON import.line_merge_motorway USING gist (geometry);

ALTER TABLE import.line_merge_motorway CLUSTER ON line_merge_motorway_ref_idx;
ALTER TABLE import.line_merge_motorway CLUSTER ON line_merge_motorway_id_idx;

--- secondary primary


DROP TABLE IF EXISTS import.line_merge_secondary;

CREATE TABLE import.line_merge_secondary AS
(
  SELECT
  ROW_NUMBER() OVER() line_merge_secondary_id,
  i.ref,
  (ST_Dump(ST_LineMerge(ST_Multi(St_Collect(i.geometry))))).geom::geometry(linestring, 3857) AS geometry
  FROM
      import.line_intersections_secondary i

  Group BY
  i.ref
);

CREATE INDEX line_merge_secondary_id_idx
   ON import.line_merge_secondary (line_merge_secondary_id);

CREATE INDEX line_merge_secondary_ref_idx
   ON import.line_merge_secondary (ref);


CREATE INDEX line_merge_secondary_geom
   ON import.line_merge_secondary USING gist (geometry);

ALTER TABLE import.line_merge_secondary CLUSTER ON line_merge_secondary_ref_idx;
ALTER TABLE import.line_merge_secondary CLUSTER ON line_merge_secondary_id_idx;



---------------------------------------------------------------------------------------------
-- 2. Schritt:
-- Es werden Schnittpunkte erstellt, die die kürzste Enfernung vom Mautknoten | St_ClosestPoint
-- zur Straßenlinie fallen. Datenquellen sind:
-- Linienzusammensetzung von line_merge.geometry
-- mautknoten_bastliste
-- Tabellenquelle: line_merge_ab, mautknoten
---------------------------------------------------------------------------------------------
-- Autobahn

DROP TABLE IF EXISTS import.line_closestPoint_motorway;

CREATE TABLE import.line_closestPoint_motorway AS
(
  SELECT
  ROW_NUMBER() OVER() line_closestPoint_motorway_id,
  a.ref as osmref,
  b.abschnitt_id,
  b.strasse,
  b.bis,
  b.von,
  b.laenge,
  b.bundesland,
  b.ortsklasse,
  b.stand,
  ST_Distance(a.geometry, b.geom) as distanz,
  ST_ClosestPoint(a.geometry,b.geom)::geometry(Point,3857) as geom
  FROM
  import.line_merge_motorway a INNER JOIN import.mautknoten b on ST_DWithin(a.geometry,b.geom, 500)
  WHERE LEFT(b.strasse,1) = 'A'  -- Distance einstellen 1500|
);

CREATE INDEX line_closestPoint_motorway_id_idx
   ON import.line_closestPoint_motorway (line_closestPoint_motorway_id);

CREATE INDEX line_closestPoint_motorway_geom_idx
   ON import.line_closestPoint_motorway (geom);

CREATE INDEX line_closestPoint_motorway_geom
   ON import.line_closestPoint_motorway USING gist (geom);

ALTER TABLE import.line_closestPoint_motorway CLUSTER ON line_closestPoint_motorway_geom_idx;
ALTER TABLE import.line_closestPoint_motorway CLUSTER ON line_closestPoint_motorway_id_idx;

-- Bundesstraße

DROP TABLE IF EXISTS import.line_closestPoint_secondary;

CREATE TABLE import.line_closestPoint_secondary AS
(SELECT
  ROW_NUMBER() OVER() line_closestPoint_secondary_id,
  a.ref as osmref,
  b.abschnitt_id,
  b.strasse,
  b.von,
  b.bis,
  b.laenge,
  b.bundesland,
  b.ortsklasse,
  b.stand,
  ST_Distance(a.geometry, b.geom) as distanz,
  ST_ClosestPoint(a.geometry,b.geom)::geometry(Point,3857) as geom
  FROM
  import.line_merge_secondary a INNER JOIN import.mautknoten b on ST_DWithin(a.geometry,b.geom, 100)
  WHERE LEFT(b.strasse,1) = 'B'  -- Distance einstellen 1500|
);

CREATE INDEX line_closestPoint_secondary_id_idx
   ON import.line_closestPoint_secondary (line_closestPoint_secondary_id);

CREATE INDEX line_closestPoint_secondary_geom_idx
   ON import.line_closestPoint_secondary (geom);

CREATE INDEX line_closestPoint_secondary_geom
   ON import.line_closestPoint_secondary USING gist (geom);

ALTER TABLE import.line_closestPoint_secondary CLUSTER ON line_closestPoint_secondary_geom_idx;
ALTER TABLE import.line_closestPoint_secondary CLUSTER ON line_closestPoint_secondary_id_idx;
---------------------------------------------------------------------------------------------
-- motorway mit secondary union in Tabelle
--> zu public schema?
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.line_closestPoint;

CREATE TABLE import.line_closestPoint AS
(
  WITH lcp AS (Select line_closestPoint_motorway_id as old_id, abschnitt_id, strasse, von, bis, laenge, bundesland, ortsklasse, distanz, stand, geom FROM import.line_closestPoint_motorway UNION Select line_closestPoint_secondary_id as old_id,abschnitt_id, strasse, von, bis, laenge, bundesland, ortsklasse, distanz, stand, geom FROM import.line_closestPoint_secondary)

  SELECT
  ROW_NUMBER() OVER() line_closestPoint_id,
  lcp.*
  FROM lcp
);

CREATE INDEX line_closestPoint_id_idx
   ON import.line_closestPoint (line_closestPoint_id);

CREATE INDEX line_closestPoint_geom_idx
   ON import.line_closestPoint (geom);

CREATE INDEX line_closestPoint_geom
   ON import.line_closestPoint USING gist (geom);

ALTER TABLE import.line_closestPoint CLUSTER ON line_closestPoint_geom_idx;
ALTER TABLE import.line_closestPoint CLUSTER ON line_closestPoint_id_idx;

---------------------------------------------------------------------------------------------
-- motorway mit secondary union in Tabelle
--> zu public schema?
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.motorway_secondary;

CREATE TABLE import.motorway_secondary AS
(
WITH ms AS (SELECT * FROM import.motorway UNION SELECT * FROM import.secondary)
SELECT

ROW_NUMBER() OVER() motorway_secondary_id,
  ms.*
FROM
  ms
);

CREATE INDEX motorway_secondary_ID_idx ON import.motorway_secondary(motorway_secondary_id);

CREATE INDEX motorway_secondary_geom ON import.motorway_secondary  USING gist (geometry);

CREATE INDEX motorway_secondary_ref_idx
  ON import.motorway_secondary
  USING btree
  (ref);

CREATE INDEX motorway_secondary_osm_id_idx
  ON import.motorway_secondary
  USING btree
  (osm_id);

CREATE INDEX motorway_secondary_type_idx
  ON import.motorway_secondary
  USING btree
  (type);

ALTER TABLE import.motorway_secondary CLUSTER ON motorway_secondary_geom;
ALTER TABLE import.motorway_secondary CLUSTER ON motorway_secondary_ID_idx;
ALTER TABLE import.motorway_secondary CLUSTER ON motorway_secondary_osm_id_idx;
ALTER TABLE import.motorway_secondary CLUSTER ON motorway_secondary_type_idx;
ALTER TABLE import.motorway_secondary CLUSTER ON motorway_secondary_ref_idx;


---------------------------------------------------------------------------------------------
-- beide intersections union in table
--> zu public schema?
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.line_intersections;

CREATE TABLE import.line_intersections AS
(WITH li AS (SELECT line_intersections_motorway_id as old_id, osm_id, ref, count, geometry FROM import.line_intersections_motorway union SELECT line_intersections_secondary_id as old_id, osm_id, ref, count, geometry FROM import.line_intersections_secondary)
    SELECT
      ROW_NUMBER() OVER() line_intersections_id,
      li.*
    FROM li
);


CREATE INDEX line_intersections_id_idx
   ON import.line_intersections (line_intersections_id);

ALTER TABLE import.line_intersections CLUSTER ON line_intersections_id_idx;

---------------------------------------------------------------------------------------------
-- 2a. Schritt:
-- line_closestPoint Tabelle wird jetzt mit osm_Attributen verschnitten
-- Tabellenquelle: trunk_motorway, line_closestPoint
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS import.line_attribute_mautknoten;

CREATE TABLE import.line_attribute_mautknoten AS
(
  Select
  ROW_NUMBER() OVER() line_attribute_mautknoten_id,
  ergebnis.*
  From
    (
      Select Distinct
      a.osm_id,
      a.type,
      regexp_replace(regexp_replace(((regexp_split_to_array(a.ref, ';'))[1]), ' ', ''), ' ', '') as ref,
      b.strasse,
      (regexp_replace(regexp_replace(((regexp_split_to_array(a.ref, ';'))[1]), ' ', ''), ' ', '') ILIKE (b.strasse )) as proof_ref,
      b.abschnitt_id,
      b.von,
      b.bis,
      concat(b.von,' : ',b.bis) as mautknotenname,
      b.laenge,
      b.stand,
      b.distanz,
      b.geom
      From
      import.motorway_secondary a,
      import.line_closestPoint b
      Where
      ST_Intersects( a.geometry , ST_Buffer(b.geom,1))
      ORDER BY mautknotenname, distanz
    ) ergebnis
 Where
  proof_ref is true-- Es werden nur die punkte angezeigt, die mit den OSM und Mautref übereinstimmen
);



ALTER TABLE import.line_attribute_mautknoten
  ADD CONSTRAINT "line_attribute_mautknoten_id_pk" PRIMARY KEY (line_attribute_mautknoten_id);

CREATE INDEX line_attribute_mautknoten_id_idx
   ON import.line_attribute_mautknoten (line_attribute_mautknoten_id);

CREATE INDEX line_attribute_mautknoten_osm_id_idx
   ON import.line_attribute_mautknoten (osm_id);

CREATE INDEX line_attribute_mautknoten_snapped_point_idx
   ON import.line_attribute_mautknoten (geom);

CREATE INDEX line_attribute_mautknoten_snapped_point
   ON import.line_attribute_mautknoten USING gist (geom);

ALTER TABLE import.line_attribute_mautknoten CLUSTER ON line_attribute_mautknoten_snapped_point;
ALTER TABLE import.line_attribute_mautknoten CLUSTER ON line_attribute_mautknoten_snapped_point_idx;
ALTER TABLE import.line_attribute_mautknoten CLUSTER ON line_attribute_mautknoten_id_idx;
ALTER TABLE import.line_attribute_mautknoten CLUSTER ON line_attribute_mautknoten_osm_id_idx;
ALTER TABLE import.line_attribute_mautknoten CLUSTER ON line_attribute_mautknoten_id_pk;


---------------------------------------------------------------------------------------------
-- 3. Schritt:
-- Erzeugt eine Tabelle, die die Anzahl der Straßensegementen ermittelt, die sich an
-- den ST_Closet_Punkten treffen
-- Tabellenquelle: line_intersections, line_attribute_mautknoten
---------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS import.osmid_mautknoten_point;

CREATE TABLE import.osmid_mautknoten_point AS
(
  SELECT
  ROW_NUMBER() OVER() AS osmid_mautknoten_point_id,
  string_agg(DISTINCT (nodes.osm_id)::text, ',') as osm_id,
  count(DISTINCT(nodes.osm_id)) as anzahl_osmid,
  string_agg(DISTINCT (nodes.type)::text, ',') as type,
  --length(streets.type) as anzahl_type,
  --nodes.mautknotennr
  nodes.geom
  FROM
  import.line_intersections streets,
  import.line_attribute_mautknoten nodes
  WHERE
  --streets.geometry && (SELECT ST_Extent(geometry) FROM osm_admin WHERE admin_level = '4' AND name ILIKE '%brandenburg%') AND
  --(nodes.geometry && (SELECT nodes.geometry FROM line_attribute_mautknoten WHERE "type" = '%' )) AND
  ST_Intersects( streets.geometry , ST_Buffer(nodes.geom,1))
  --    streets.geometry && ST_Buffer(nodes.snapped_point,1) -- Abfrage über einer Boundingbox
  GROUP BY nodes.geom
);

ALTER TABLE import.osmid_mautknoten_point
  ADD CONSTRAINT osmid_mautknoten_point_id_pk PRIMARY KEY (osmid_mautknoten_point_id);

CREATE INDEX osmid_mautknoten_point_idx ON import.osmid_mautknoten_point (osmid_mautknoten_point_id);
CREATE INDEX osmid_mautknoten_point_snapped_point_idx ON import.osmid_mautknoten_point (geom);

CREATE INDEX osmid_mautknoten_point_geom ON import.osmid_mautknoten_point  USING gist (geom);

ALTER TABLE import.osmid_mautknoten_point CLUSTER ON osmid_mautknoten_point_geom;
ALTER TABLE import.osmid_mautknoten_point CLUSTER ON osmid_mautknoten_point_idx;
ALTER TABLE import.osmid_mautknoten_point CLUSTER ON osmid_mautknoten_point_snapped_point_idx;
ALTER TABLE import.osmid_mautknoten_point CLUSTER ON osmid_mautknoten_point_id_pk;

---------------------------------------------------------------------------------------------
-- 4. Schritt:
-- Es wird ein Ranking erstellt wie die Distanz der Schnittpunkte zu den Mautpunkten ist | Vergleichbar Order by
-- wichtig für das Filtern im Schritt 4
-- Tabellenquelle: line_attribute_mautknoten
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS osmid_trunkpoint_ranking;

CREATE TABLE osmid_trunkpoint_ranking AS
(
  select
  ROW_NUMBER() OVER() osmid_trunkpoint_ranking_id,
  tmp.*
  from (
    select
    *,
    row_number() over (partition by mautknotenname, ref order by distanz) as ranking
    from line_attribute_pointtrunk
    --Where
    --(anzahl_osmid =1 AND oneway = 1)
  ) tmp
  where ranking <= 6
  Order by mautknotenname, ref
);


ALTER TABLE public.osmid_trunkpoint_ranking
  ADD CONSTRAINT osmid_trunkpoint_ranking_id_pk PRIMARY KEY (osmid_trunkpoint_ranking_id);

CREATE INDEX osmid_trunkpoint_ranking_idx ON public.osmid_trunkpoint_ranking (osmid_trunkpoint_ranking_id);
CREATE INDEX osmid_trunkpoint_ranking_snapped_point_idx ON public.osmid_trunkpoint_ranking (geom);

CREATE INDEX osmid_trunkpoint_ranking_geom ON public.osmid_trunkpoint_ranking  USING gist (geom);

ALTER TABLE public.osmid_trunkpoint_ranking CLUSTER ON osmid_trunkpoint_ranking_geom;
ALTER TABLE public.osmid_trunkpoint_ranking CLUSTER ON osmid_trunkpoint_ranking_idx;
ALTER TABLE public.osmid_trunkpoint_ranking CLUSTER ON osmid_trunkpoint_ranking_snapped_point_idx;
ALTER TABLE public.osmid_trunkpoint_ranking CLUSTER ON osmid_trunkpoint_ranking_id_pk;


---------------------------------------------------------------------------------------------
-- 4. Schritt:
-- Es wird eine Tabelle erzeugt, wo die Vergleichs-Attribute ranking, und anzahl_osmid genutzt werden
-- um eine finale st_closest_Punkttabelle zu erstellen
-- Tabellenquelle: line_attribute_pointtrunk, osmid_mautknoten_point, osmid_trunkpoint_ranking
---------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS osmid_trunkpoint_join;

CREATE TABLE osmid_trunkpoint_join AS
(
Select
  ROW_NUMBER() OVER() osmid_trunkpoint_join_id,
  punkte.*,
  merge.anzahl_osmid,
  merge.ranking
FROM
  line_attribute_pointtrunk punkte,
  (
  Select
  osmranking.*,
  osmpoints.anzahl_osmid
  -- osmpoints.osm_id as test_osm_id -- Überprüfung der osmpoints.osm_id
  From
  osmid_mautknoten_point osmpoints,
  osmid_trunkpoint_ranking osmranking
  Where
  osmranking.geom && osmpoints.geom
  ) merge
Where
punkte.geom && merge.geom
AND
( merge.ranking <= 4 OR merge.anzahl_osmid = 1)
     --   AND
     --   (
    --(punkte.ref like '^B' AND punkte.proof_ref is true) -- Filtern nach ref 'B'
    --OR
    --(osmpoints.anzahl_osmid = '1' AND punkte.proof_ref is true) -- Filtern nach der räumlichen Lage und der Anzahl der Straßensegmenten und der Bundsstraßennummer
   -- OR
   -- (osmpoints.type = 'primary,trunk' AND osmpoints.anzahl_osmid = '2')
    --(length(osmpoints.type) IN (13,14) AND osmpoints.anzahl_osmid = '2') -- Filtern nach der Zeichnenlaenge und der Anzahl
   -- OR (punkte.proof_ref is true )--AND osmpoints.anzahl_osmid = '2')
  --)
);



ALTER TABLE public.osmid_trunkpoint_join
  ADD CONSTRAINT osmid_trunkpoint_join_id_pk PRIMARY KEY (osmid_trunkpoint_join_id);

CREATE INDEX osmid_trunkpoint_join_idx ON public.osmid_trunkpoint_join (osmid_trunkpoint_join_id);
CREATE INDEX osmid_trunkpoint_join_geom_idx ON public.osmid_trunkpoint_join (geom);

CREATE INDEX osmid_trunkpoint_join_geom ON public.osmid_trunkpoint_join  USING gist (geom);

ALTER TABLE public.osmid_trunkpoint_join CLUSTER ON osmid_trunkpoint_join_geom;
ALTER TABLE public.osmid_trunkpoint_join CLUSTER ON osmid_trunkpoint_join_idx;
ALTER TABLE public.osmid_trunkpoint_join CLUSTER ON osmid_trunkpoint_join_geom_idx;
ALTER TABLE public.osmid_trunkpoint_join CLUSTER ON osmid_trunkpoint_join_id_pk;



---------------------------------------------------------------------------------------------
-- 5. Schritt:
-- Es wird ein Datensatz erzeugt, wo sich die Straßendaten von OSM an den Mautschnittpunkten schneiden und geteilt werden. --
---------------------------------------------------------------------------------------------
 --SELECT result.path , ST_AsText(result.geom)
 --FROM ST_GeomFromText('LINESTRING( 0 0 ,10 10 , 20 10 )',932011) AS line
 --, ST_GeomFromText('point ( 15.05 10.04)',932011) AS point
 --,rc_split_line_by_points(
 --input_line:=line
 --,input_points:=point
 --,tolerance:=4
 --) AS result;
---SELECT UpdateGeometrySRID('XXX','the_geom',3857);

--DROP TABLE splittest;
--CREATE TABLE splittest AS
--(
--´SELECT
-- ROW_NUMBER() OVER() AS myid,
 --ST_Distance(punkte.geom,streets.geometry) as abstand,
-- result.path,
 --streets.ref,
 --streets.osm_id,
--  result.geom AS geom
-- FROM
--  trunk_motorway streets,
--  osmid_trunkpoint_join punkte,
--  rc_split_line_by_points(input_line:=streets.geometry,input_points:=punkte.geom,tolerance:=4) AS result
 --WHERE
 --ST_Intersects( streets.geometry , ST_Buffer(punkte.geom,1))
-- Group by
-- result.path,
-- result.geom

--);

