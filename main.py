import requests
import csv
import zipfile
import io
import codecs
from db_handler import db_execute
import time
from os import listdir
from config_importer import import_config
import subprocess

#-----------------------------------Variables---------------------------------#
datestring = None
csv_path = None
files = None
#-------------------------Mautabelle csv Download-----------------------------#

def update_mautabelle_csv():

    url = "http://www.mauttabelle.de/akt_version.txt"
    response = requests.get(url)
    version = response.text
    vday = "01"
    vyear = version[:4]
    vmonth = version[-2:]
    print("---> aktuellste Mauttabelle online vom: {} {}".format(vyear, vmonth))
    datestring = vyear + "-" + vmonth + "-" + vday
    filename = datestring + "_Mauttabelle"

    csv_path = "./" + filename + ".csv"
    
    files = []
    try:
        filenames = listdir("./")
        filenames = [filename for filename in filenames if filename.endswith(".csv")]
        for filename in filenames:
            files.append(filename)
        files = sorted(files, reverse=True)
        fyear = files[0][:4]
        fmonth = files[0][5:7]
        print("---> Version csv: {} {}".format(fyear, fmonth))

    except:
        pass


    if len(files) == 0:
        print("---> Noch keine Daten verfügbar")
        print("")
        create_table()
        download(datestring)
        insert_new(datestring, csv_path)

    elif int(fyear) < int(vyear) or int(fmonth) < int(vmonth):
        print("---> Neuere Daten verfügbar")
        print("")
        download(datestring)
        insert_new(datestring, csv_path)

    else:
        print("---> Kein Update verfügbar")
        print("")
        
    print("---> Fertig!")
    print("")


def download(datestring):
    zipname = datestring + "_Mauttabelle.zip"
    url = "http://www.mauttabelle.de/{}".format(zipname)
    print(url)
    print("---> Mauttabelle downloaden...")
    print("")
    req = requests.get(url)
    print(req)
    zip = zipfile.ZipFile(io.BytesIO(req.content))
    zip.extractall()

#-------------------------Update csv in Datenbank-----------------------------#

def check_table(): #funktioniert nicht

    check_table_exists = """SELECT EXISTS (
       SELECT 1 
       FROM   pg_tables
       WHERE  schemaname = 'public'
       AND    tablename = 'mauttabelle'
       );"""


    rows = db_execute(check_table_exists, None)
    for row in rows:
        if row[0] == True:
            print("---> Mauttabelle bereits in Datenbank vorhanden")
            print("")

        else:
            print("---> Noch keine Mauttabelle in Datenbank osm vorhanden")
            print("")
            

def create_table():
    
    sqls = ("CREATE SCHEMA IF NOT EXISTS import;",
            "CREATE EXTENSION IF NOT EXISTS POSTGIS;",
            "DELETE from import.mauttabelle;",
            "DROP TABLE IF EXISTS import.mauttabelle;",
            "DROP INDEX IF EXISTS import.idx_m_id;",
            "DROP INDEX IF EXISTS import.idx_m_abs_id;",
            "DROP INDEX IF EXISTS import.idx_m_mk_von;",
            "DROP INDEX IF EXISTS import.idx_m_mk_bis;",
            "VACUUM ANALYZE;",
            """CREATE TABLE IF NOT EXISTS import.mauttabelle (
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
            stand date
        );""")
    
    print("---> Lösche alte Einträge aus Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import'...")
    print("")
    print("---> Erstelle Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import'")
    print("")

    for sql in sqls:
        db_execute(sql, None)

def insert_new(datestring, csv_path):
    start_time = time.time()
    

    print("---> Erstelle neue Einträge in Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import' ...")
    print("")
    # count row for insert
    i = 1
    with codecs.open(csv_path, encoding="latin_1") as f:
        reader = csv.reader(f, delimiter=';')
        next(reader)

        for row in reader:
            row.append(datestring)

            values = (int(row[0]), row[1], float(row[2].replace(",",".")), row[3], float(row[4]), float(row[5]), row[6], float(row[7]), float(row[8]), row[9], int(row[10]), row[11])
            print(i, values)
            sql = "INSERT INTO import.mauttabelle(abschnitt_id, strasse, laenge, von, lat_von, lon_von, bis, lat_bis, lon_bis, bundesland, ortsklasse, stand)" \
                              "Values(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            db_execute(sql, values)
            i = i + 1

    print("---> Erstelle Geometrien und Index für Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import'...")
    print("")
    sqls = ("SELECT AddGeometryColumn ('import.mauttabelle','mk_von','geom',3857,'POINT',2);",
            "SELECT AddGeometryColumn ('import.mauttabelle','mk_bis','geom',3857,'POINT',2);",
            "update import.mauttabelle as m set mk_von = ST_SetSRID(ST_MakePoint(m.lon_von, m.lat_von), 3857);",
            "update import.mauttabelle as m set mk_bis = ST_SetSRID(ST_MakePoint(m.lon_bis, m.lat_bis), 3857);",
            "CREATE INDEX idx_m_id ON mauttabelle USING btree (id);",
            "CREATE INDEX idx_m_abs_id ON import.mauttabelle USING btree (abschnitt_id);",
            "CREATE INDEX idx_m_mk_von ON import.mauttabelle USING gist (mk_von);",
            "CREATE INDEX idx_m_mk_bis ON import.mauttabelle USING gist (mk_bis);"
            )
    for sql in sqls:
        db_execute(sql, None)

    time_elapsed = (time.time() - start_time) / 60
    print("---> {} Einträge in Tabelle 'Mauttabelle' Schema 'import' erstellt. Fertig nach {} Minuten".format(i, time_elapsed))
    print("")

def imposm_import():
    start_time = time.time()
    args = import_config("./config.txt", "imposm_import", "cmd")
    print(args)
    cmd = subprocess.Popen(args, shell=True)
    cmd.communicate()
    #print(cmd.returncode)
    time_elapsed = (time.time() - start_time) / 60
    print("---> Imposm Import in Tabelle 'Mauttabelle' Schema 'import' fertig nach {} Minuten".format(time_elapsed))
    print("")


def postgis_processing():

    # Straßen werden gefiltert | Motorway, Trunk, Primary
    args = import_config("/users/david/ba/mauttabelle/sql/pg_1.sql","imposm_import", "cmd")

    # Punkte suchen, Filtern und Straßen anhand eines Punktes splitten

    # Straßentopologie anhand der Punkte teilen -> erstmal manuell via ArcGIS





if __name__ == "__main__":
    update_mautabelle_csv()
    #imposm_import()

    
   











