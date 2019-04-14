---------------------------------------------------------------------------------------------
-- 6. Analyseschritt: Auswertungstabelle erstellen 
---------------------------------------------------------------------------------------------
-- 6.1. Schritt: 
-- Tabelle osm_auswertung wird erzeugt, wo beide routinggraphen zusammengefasst werden
-- Außerdem wird eine Spalte mit Auswertung erzeugt, mit dem Bewertungskritieren
-- 'gut', 'ändern', 'schlecht'
---------------------------------------------------------------------------------------------
Drop Table osm_auswertung;

Create Table osm_auswertung As
(
Select
ROW_NUMBER() OVER() as ID,
erg.*,
CASE
	WHEN toll=1 AND toll_hgv=1 AND toll_n3=1 THEN 'gut'
	--WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'gut'
	WHEN toll=0 AND toll_hgv=1 AND toll_n3=1 THEN 'ändern'
	WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
	WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
	WHEN toll=0 AND toll_hgv=1 AND toll_n3=0 THEN 'ändern'
	WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
	ELSE 'schlecht'
END as auswertung
FROM
	(
	SELECT
	t1.von,
	t1.nach,
	t1.osm_id,
	t1.ref,
	t1.toll,
	t1.toll_hgv,
	t1.toll_n3,
	t1.edge_geom
	FROM
	"mautknoten_routing_left" t1
	UNION
	SELECT
	t2.von,
	t2.nach,
	t2.osm_id,
	t2.ref,
	t2.toll,
	t2.toll_hgv,
	t2.toll_n3,
	t2.edge_geom
	FROM
	"mautknoten_routing_right" t2
	)erg
Order by toll, toll_hgv,toll_n3
);


----------------------------------------------------------
-- 6.2. Schritt:
-- Tabelle osm_auswertung2
-- > ergebis wird leicht verändert für Testzwecke
----------------------------------------------------------
Drop Table osm_auswertung2;

create Table osm_auswertung2 as
(
SELECT
*
From
osm_auswertung
ORDER by von, nach
);

UPDATE   public.osm_auswertung2
   SET   toll =
	CASE WHEN  "toll"=0 AND  "toll_hgv"=1 AND "toll_n3"  =1 THEN 1 ELSE 0 END;

--UPDATE public.osm_auswertung2
--   SET toll_hgv =
--	CASE WHEN  "toll"=1 AND  "toll_hgv"=0 AND "toll_n3"  =1 THEN 1 ELSE 0 END;

UPDATE public.osm_auswertung2
   SET auswertung =
	CASE
		WHEN toll=1 AND toll_hgv=1 AND toll_n3=1 THEN 'gut'
		--WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'gut'
		WHEN toll=0 AND toll_hgv=1 AND toll_n3=1 THEN 'aendern'
		WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'aendern'
		WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'aendern'
		WHEN toll=0 AND toll_hgv=1 AND toll_n3=0 THEN 'aendern'
		WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'aendern'
		ELSE 'schlecht'
	END;

VACUUM ANALYZE;



--Drop Table test2;
--Create table test2 as
--(
--SELECT
--*,
--CASE
--	WHEN toll=1 AND toll_hgv=1 AND toll_n3=1 THEN 'gut'
--	--WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'gut'
--	WHEN toll=0 AND toll_hgv=1 AND toll_n3=1 THEN 'ändern'
--	WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
--	WHEN toll=1 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
--	WHEN toll=0 AND toll_hgv=1 AND toll_n3=0 THEN 'ändern'
--	WHEN toll=0 AND toll_hgv=0 AND toll_n3=1 THEN 'ändern'
--	ELSE 'schlecht'
--END as auswertung
--FROM
--test
--Order by toll, toll_hgv,toll_n3
--);
