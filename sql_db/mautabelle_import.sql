--Extensions

VACUUM ANALYZE;
CREATE EXTENSION IF NOT EXISTS POSTGIS;
CREATE EXTENSION IF NOT EXISTS PGROUTING;
CREATE SCHEMA IF NOT EXISTS import;

-- Mauttabelle import


DROP TABLE IF EXISTS import.mauttabelle;

CREATE TABLE IF NOT EXISTS import.mauttabelle (
id SERIAL,
abschnitt_id integer NOT NULL PRIMARY KEY,
strasse varchar(255),
laenge numeric NOT NULL,
von varchar(255),
lat_von numeric NOT NULL,
lon_von numeric NOT NULL,
bis varchar(255),
lat_bis numeric NOT NULL,
lon_bis numeric NOT NULL,
bundesland varchar(4),
ortsklasse integer,
stand date);

