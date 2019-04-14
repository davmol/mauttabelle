---------------------------------------------------------------------------------------------
-- 3. Analyseschritt: Erstellung einer Straßentopologie via pgrouting
---------------------------------------------------------------------------------------------
-- 3.1 Vorabänderung: 

-- WENN Fehlermeldung bitte ID löschen und ID_0 zu ID ändern!!!
---------------------------------------------------------------------------------------------
 Alter Table public."trunk_motorway_primary_routing"
	drop COLUMN IF EXISTS id;

 Alter Table public."trunk_motorway_primary_routing"
	drop COLUMN IF EXISTS trunk_moto;

 Alter Table public."trunk_motorway_primary_routing"
	drop COLUMN IF EXISTS "source";

 Alter Table public."trunk_motorway_primary_routing"
	drop COLUMN IF EXISTS "target";
	
--ALTER TABLE public."trunk_motorway_primary_routing"
--  ADD COLUMN id integer;

-- ALTER TABLE public."trunk_motorway_primary_routing"
--   RENAME COLUMN id_0 TO id;

--ALTER TABLE public."trunk_motorway_primary_routing"
--   RENAME COLUMN gid TO id;

----------------------------------------------------------------------------------------------

CREATE INDEX trunk_motorway_primary_routing_geom ON public.trunk_motorway_primary_routing USING gist (geom);
ALTER TABLE public.trunk_motorway_primary_routing CLUSTER ON trunk_motorway_primary_routing_geom;

CREATE INDEX trunk_motorway_primary_routing_id_idx ON public.trunk_motorway_primary_routing USING btree (gid);

-- Source and Target Column
ALTER TABLE trunk_motorway_primary_routing ADD COLUMN "source" integer;
ALTER TABLE trunk_motorway_primary_routing ADD COLUMN "target" integer;

-- Add cost column
ALTER TABLE trunk_motorway_primary_routing  ADD COLUMN length double precision;
UPDATE trunk_motorway_primary_routing SET length = ST_LENGTH(geom);

-- Make the cost column different depending on road type
--UPDATE trunk_motorway_primary_routing 
--	SET length = CASE 
--		WHEN class='motorways' THEN ST_LENGTH(geom)/4
--		WHEN class='railways' THEN 99999999 
--		ELSE ST_LENGTH(geom) 
--		END;

-- Erzeuge Straßentopologie und analysiere den Straßengraph

SELECT pgr_createTopology('trunk_motorway_primary_routing',0.0001, 'geom', 'gid');
SELECT pgr_analyzeGraph('trunk_motorway_primary_routing',0.0001,'geom', 'gid');

--SELECT pgr_analyzeOneway('trunk_motorway_primary_routing',
--    ARRAY['0', '1'],
--    ARRAY['0', '1'],
--    ARRAY['0', '1'],
--    ARRAY['0', '1'],
--    '0');

--SELECT pgr_analyzeOneway('trunk_motorway_primary_routing',
--    ARRAY['0','0', '1'], -- source IN
--    ARRAY['0','1', '0'], -- source OUT
--    ARRAY['0','1', '0'], -- target IN
--    ARRAY['0','0', '1'],-- target OUT
--    '0');

-- Oneway-Regeln erstellen

ALTER TABLE public."trunk_motorway_primary_routing"
	ADD COLUMN rules character varying(4);

UPDATE trunk_motorway_primary_routing 
SET rules= CASE 
	WHEN (oneway=0) THEN 'B'   -- both ways
	WHEN (oneway=1) THEN 'FT'  -- direction of the LINESSTRING
	WHEN (oneway=-1) THEN 'TF'  -- reverse direction of the LINESTRING
	ELSE '' END;                -- unknown

-- Pg-Routing Onewayanlayse durchführen

SELECT pgr_analyzeOneway('trunk_motorway_primary_routing',
	ARRAY['', 'B', 'TF'],
	ARRAY['', 'B', 'FT'],
	ARRAY['', 'B', 'FT'],
	ARRAY['', 'B', 'TF'],
	oneway:='rules');

--Identify nodes with problems
-- SELECT * FROM trunk_motorway_primary_routing_vertices_pgr WHERE ein=0 OR eout=0;

--Identify the links at nodes with problems
-- CREATE TABLE public.ProblemOneway AS
--(
--	SELECT gid,name,type,ref,oneway,a.geom
--	FROM trunk_motorway_primary_routing a,-
--	trunk_motorway_primary_routing_vertices_pgr b 
--	WHERE a.source=b.id AND ein=0 OR eout=0
--	UNION
--	SELECT gid,name,type,ref,oneway,
--	a.geom
--	FROM trunk_motorway_primary_routing a,trunk_motorway_primary_routing_vertices_pgr b 
--	WHERE a.target=b.id AND ein=0 OR eout=0
--);

-- clean up the database because we have updated a lot of records
VACUUM ANALYZE VERBOSE trunk_motorway_primary_routing;
