---------------------------------------------------------------------------------------------
-- 5. Analyseschritt: Start-Ziel Routing auf Grundlage der Mautpunkte
---------------------------------------------------------------------------------------------
-- Erstellung eines Routinggraphs durch die Pg_funktion
-- „pgr_dijkstra - Shortest Path Dijkstra"
---------------------------------------------------------------------------------------------
-- 5.1. Schritt:
-- Erstellung eines Routinggraphs in der Fahrrichtung "left" --
---------------------------------------------------------------------------------------------

DROP TABLE mautknoten_routing_left;

CREATE TABLE mautknoten_routing_left AS
(
    SELECT
    result.node AS result_node,
    result.von,
    result.nach,
    --roads_topo.node.geom AS node_geom,
    result.edge AS result_edge,
    routing.osm_id,
    routing.ref,
    routing.toll::smallint,
    routing.toll_hgv::smallint,
    routing.toll_N3::smallint,
    routing.toll_opera as toll_operator,
    routing.hgv::smallint,
    routing.hazmat::smallint,
    routing.geom AS edge_geom
    FROM
    trunk_motorway_primary_routing routing
    JOIN
    (
    Select
    route.startnode,
    route.endnode,
    route.von,
    route.nach,
    unnest(ARRAY[route.node]) as node,
    unnest(ARRAY[route.edge]) as edge
    FROM
        (
        SELECT
        --startziel.startnode::text ||','||startziel.endnode::text as Startziel,
        startziel.startnode,
        startziel.endnode,
        startziel.von::text,
        startziel.nach::text,
        array_agg(result.seq),
        array_agg(result.id1) as node,
        array_agg(result.id2) as edge,
        array_agg(liste.name),
        Count(liste.name)

        FROM
        (
            SELECT
            erg1.startnode,
            erg1.von,
            erg2.nach,
            erg2.endnode
            FROM
            (
                SELECT
                a.von,
                a.nach,
                b.node_id::integer as startnode
                FROM
                mautknoten_bastliste a
                RIGHT JOIN
                mautknotennode_pgrouting b
                ON
                (a.von = b.name)
                GROUP by
                a.von,
                a.nach,
                b.node_id
            ) erg1,
            (
                SELECT
                a.von,
                a.nach,
                b.node_id::integer as endnode
                FROM
                mautknoten_bastliste a
                RIGHT JOIN
                mautknotennode_pgrouting b
                ON
                (a.nach = b.name)
                GROUP by
                a.nach,
                a.von,
                b.node_id
            )erg2,
             mautknoten_bastliste bast
            Where
             (bast.von = erg1.von AND bast.nach = erg2.nach)
            Group by
            erg1.startnode,
            erg1.von,
            erg2.nach,
            erg2.endnode
        ) startziel,
           pgr_dijkstra('SELECT gid AS id, source::int4 AS source, target::int4 AS target, length::float8 AS cost, length::float8
        AS reverse_cost FROM trunk_motorway_primary_routing',
                 startziel.startnode,startziel.endnode, TRUE, false)result
        left outer join
        (
            SELECT
            a.node_id,
            b.name
            FROM
            mautknotennode_pgrouting a,
            mautknoten_germany b
            WHERE
            a.mautknotenname = b.name
        ) as liste
        ON (liste.node_id =result.id1 )
        --Where
        --(startziel.von LIKE 'B101N Ludwigsfelde Sued' AND startziel.nach LIKE 'B101N Thyrow')
        GROUP BY
        startziel.startnode,
        startziel.von,
        startziel.nach,
        startziel.endnode
        --result.id1
    )route
    Where
    Count =2
    ) result
    ON routing.gid = result.edge
);

CREATE INDEX mautknoten_routing_left_geom ON public.mautknoten_routing_left USING gist (edge_geom);

ALTER TABLE public.mautknoten_routing_left CLUSTER ON mautknoten_routing_left_geom;

--------------------------------------------------------------------------------------------
-- 5.2. Schritt:
-- Erstellung eines Routinggraphs in der Gegenfahrrichtung "right".
--------------------------------------------------------------------------------------------

Drop Table mautknoten_routing_right;
CREATE TABLE mautknoten_routing_right AS
(
    SELECT
    result.node AS result_node,
    --maut.name,
    result.nach,
    result.von,
    --roads_topo.node.geom AS node_geom,
    result.edge AS result_edge,
    routing.osm_id,
    routing.ref,
    routing.toll::smallint,
    routing.toll_hgv::smallint,
    routing.toll_N3::smallint,
    routing.toll_opera as toll_operator,
    routing.hgv::smallint,
    routing.hazmat::smallint,
    routing.geom AS edge_geom
    FROM
    trunk_motorway_primary_routing routing
    JOIN
    (
    Select
    route.startnode,
    route.endnode,
    route.von,
    route.nach,
    unnest(ARRAY[route.node]) as node,
    unnest(ARRAY[route.edge]) as edge
    FROM
        (
        SELECT
        --startziel.startnode::text ||','||startziel.endnode::text as Startziel,
        startziel.startnode,
        startziel.endnode,
        startziel.von::text,
        startziel.nach::text,
        array_agg(result.seq),
        array_agg(result.id1) as node,
        array_agg(result.id2) as edge,
        array_agg(liste.name),
        Count(liste.name)

        FROM
        (
            SELECT
            erg1.startnode,
            erg1.von,
            erg2.nach,
            erg2.endnode
            FROM
            (
                SELECT
                a.von,
                a.nach,
                b.node_id::integer as startnode
                FROM
                mautknoten_bastliste a
                RIGHT JOIN
                mautknotennode_pgrouting b
                ON
                (a.von = b.name)
                GROUP by
                a.von,
                a.nach,
                b.node_id
            ) erg1,
            (
                SELECT
                a.von,
                a.nach,
                b.node_id::integer as endnode
                FROM
                mautknoten_bastliste a
                RIGHT JOIN
                mautknotennode_pgrouting b
                ON
                (a.nach = b.name)
                GROUP by
                a.nach,
                a.von,
                b.node_id
            )erg2,
             mautknoten_bastliste bast
            Where
             (bast.von = erg1.von AND bast.nach = erg2.nach)
            Group by
            erg1.startnode,
            erg1.von,
            erg2.nach,
            erg2.endnode
        ) startziel,
           pgr_dijkstra('SELECT gid AS id, source::int4 AS source, target::int4 AS target, length::float8 AS cost, length::float8
        AS reverse_cost FROM trunk_motorway_primary_routing',
                 startziel.endnode,startziel.startnode, TRUE, false)result
        left outer join
        (
            SELECT
            a.node_id,
            b.name
            FROM
            mautknotennode_pgrouting a,
            mautknoten_germany b
            WHERE
            a.mautknotenname = b.name
        ) as liste
        ON (liste.node_id =result.id1 )
        --Where
        --(startziel.von LIKE 'B101N Ludwigsfelde Sued' AND startziel.nach LIKE 'B101N Thyrow')
        GROUP BY
        startziel.startnode,
        startziel.von,
        startziel.nach,
        startziel.endnode
        --result.id1
    )route
    Where
    Count =2
    ) result
    ON routing.gid = result.edge
);

CREATE INDEX mautknoten_routing_right_geom ON public.mautknoten_routing_right USING gist (edge_geom);

ALTER TABLE public.mautknoten_routing_right CLUSTER ON mautknoten_routing_right_geom;



------------------------------------------------------------------------------------------------------------------
