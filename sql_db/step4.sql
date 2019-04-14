---------------------------------------------------------------------------------------------
-- 4. Analyseschritt: Erzeugung der Mautabschnitte
-- Erzeugen einer Bastlisten-Tabelle, wo die Node-ID der Straßentopologie
-- an der Mautknotennummer zugeordnet sind
-- Tabellenquelle: trunk_motorway_primary_routing_vertices_pgr, line_attribute_pointtrunk, osmid_trunkpoint_join, mautknoten_germany
---------------------------------------------------------------------------------------------

Drop Table IF EXISTS mautknotennode_pgrouting;


CREATE TABLE public.mautknotennode_pgrouting AS
(
  Select Distinct
  ROW_NUMBER() OVER() AS mautknotennode_pgrouting_id,
  rout.id as node_id,
  punkte.ref,
  osm.mautknotenname,
  bast.name,
  osm.geom
  FROM
  trunk_motorway_primary_routing_vertices_pgr rout,
  public.line_attribute_pointtrunk punkte,
  public.osmid_trunkpoint_join osm,
  public.mautknoten_germany bast
  WHERE
  (punkte.geom =osm.geom
  AND
  osm.geom = rout.the_geom
  AND
  upper(osm.mautknotenname) = upper(bast.name))
  Group by
  node_id,
  punkte.ref,
  osm.mautknotenname,
  bast.name,
  osm.geom
  ORDER by mautknotenname, ref
);


ALTER TABLE public.mautknotennode_pgrouting
  ADD CONSTRAINT "mautknotennode_pgrouting_id_pk" PRIMARY KEY (mautknotennode_pgrouting_id);

CREATE INDEX mautknotennode_pgrouting_id_idx
   ON public.mautknotennode_pgrouting (mautknotennode_pgrouting_id);

CREATE INDEX mautknotennode_pgrouting_geom
   ON public.mautknotennode_pgrouting USING gist (geom);

ALTER TABLE public.mautknotennode_pgrouting CLUSTER ON mautknotennode_pgrouting_geom;