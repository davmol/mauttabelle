
create table mauttabelle 

id int pkey not null
länge float
von text
breite von float
länge von float
nach text
breite bis float
länge bis float
bundesland text 
ortsklasse int

CREATE TABLE IF NOT EXISTS mauttabelle (
    abschnitt_id integer NOT NULL PRIMARY KEY,
    strasse varchar(255),
    laenge numeric NOT NULL,
    von varchar(255),
    lat_von numeric NOT NULL,
    lon_von numeric NOT NULL,
    nach varchar(255),
   	lat_bis numeric NOT NULL,
    lon_bis numeric NOT NULL,
    bundesland varchar(4),
    ortsklasse integer,
    stand date
);


ALTER TABLE mauttabelle
ADD COLUMN mk_von geometry;

ALTER TABLE mauttabelle
ADD COLUMN mk_bis geometry;


update mauttabelle as m set mk_von = ST_SetSRID(ST_MakePoint(m.lon_von, m.lat_von),4326);


update mauttabelle as m set mk_bis = ST_SetSRID(ST_MakePoint(m.lon_bis, m.lat_bis),4326);