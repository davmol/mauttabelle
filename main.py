#!/usr/bin/env python3
# -*- coding: utf-8 -*-



import requests
import csv
import zipfile
import io
import codecs
from db_handler import sql_execute, sqlfile_exectute
import time
from os import listdir
from config_importer import import_config
import subprocess
import os
import shutil

# -----------------------------------Variables---------------------------------#

# workspace Verzeichnis
workspace = "/Users/david/BA"
# config Datei für User udn System spezifische Parameter
config_file = "/Users/david/BA/mauttabelle/config.txt"
# Geofabrik Germamy pbf url
pbf_url = "https://download.geofabrik.de/europe/germany-latest.osm.pbf"
# Mauttabelle url
mauttabelle_url = "http://www.mauttabelle.de/"



# -------------------------Mautabelle csv Download-----------------------------#
def pbf_download():
    print("---> Downloade neuste Germany pbf von Geofabrik")
    print("")
    local_filename = pbf_url.split('/')[-1]
    r = requests.get(pbf_url, stream=True)
    with open(workspace + "/" + "pbf" + "/" + local_filename, 'wb') as file:
        shutil.copyfileobj(r.raw, file)

    print("---> Download fertig")
    print("")


def download_mauttabelle(datestring):
    zipname = datestring + "_Mauttabelle.zip"
    url = mauttabelle_url + zipname
    print(url)
    print("---> Mauttabelle downloaden...")
    print("")
    req = requests.get(url)
    print(req)
    zip = zipfile.ZipFile(io.BytesIO(req.content))
    zip.extractall()


def update_mautabelle():
    url = "http://www.mauttabelle.de/akt_version.txt"
    response = requests.get(url)
    version = response.text
    vday = "01"
    vyear = version[:4]
    vmonth = version[-2:]
    print("---> aktuellste Mauttabelle von BAST ist vom: {} {}".format(vyear, vmonth))
    datestring = vyear + "-" + vmonth + "-" + vday
    filename = datestring + "_Mauttabelle"

    mauttabelle_csv = filename + ".csv"
    mauttabelle_path = workspace + "/" + mauttabelle_csv

    files = []

    try:
        filenames = listdir("./")
        filenames = [filename for filename in filenames if filename.endswith(".csv")]
        for filename in filenames:
            files.append(filename)
        files = sorted(files, reverse=True)
        fyear = files[0][:4]
        fmonth = files[0][5:7]
        print("---> Lokale Version der Mauttabelle ist vom: {} {}".format(fyear, fmonth))

    except:
        pass

    if len(files) == 0:
        print("---> Noch keine Mauttabelle lokal verfügbar")
        print("")
        download_mauttabelle(datestring)
        create_mauttabelle(datestring, mauttabelle_path)

    elif int(fyear) < int(vyear) or int(fmonth) < int(vmonth):
        print("---> Neuere Mauttabelle von der BAST verfügbar")
        print("")
        download_mauttabelle(datestring)
        create_mauttabelle(datestring, mauttabelle_csv)

        print("---> Arichiviere ältere lokale Version der Mauttabelle vom: {} {}".format(fyear, fmonth))
        print("")
        shutil.move(mauttabelle_path, workspace + "/" + "mauttabelle_backup" + "/" + mauttabelle_csv)

    else:
        print("---> Keine neue Mauttabelle von der BAST verfügbar")
        print("")
        print("---> Beende!")
        print("")


def check_table():  # funktioniert nicht

    check_table_exists = """SELECT EXISTS (
       SELECT 1 
       FROM   pg_tables
       WHERE  schemaname = 'public'
       AND    tablename = 'mauttabelle'
       );"""

    rows = sql_execute(check_table_exists, None)
    for row in rows:
        if row[0] == True:
            print("---> Mauttabelle bereits in Datenbank vorhanden")
            print("")

        else:
            print("---> Noch keine Mauttabelle in Datenbank osm vorhanden")
            print("")


def create_mauttabelle(datestring, csv_path):
    start_time = time.time()
    print("---> Lösche alte Einträge aus Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import'...")
    print("")
    print("---> Erstelle Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import'")
    print("")

    step1 = import_config(config_file, "sqlfiles", "mautabelle_import")
    sqlfile_exectute(step1)

    print("---> Erstelle neue Einträge in Tabelle 'Mauttabelle' in Datenbank 'osm' Schema 'import' ...")
    print("")
    # count row for insert

    with codecs.open(csv_path, encoding="latin_1") as f:
        reader = csv.reader(f, delimiter=';')
        next(reader)

        for index, row in enumerate(reader):
            row.append(datestring)

            values = (
                int(row[0]), row[1], float(row[2].replace(",", ".")), row[3], float(row[4]), float(row[5]), row[6],
                float(row[7]), float(row[8]), row[9], int(row[10]), row[11])
            print(index + 1, values)
            sql = "INSERT INTO import.mauttabelle(abschnitt_id, strasse, laenge, von, lat_von, lon_von, bis, lat_bis, lon_bis, bundesland, ortsklasse, stand)" \
                  "Values(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            sql_execute(sql, values)

    time_elapsed = round((time.time() - start_time) / 60)
    print("---> {} Einträge in Tabelle 'Mauttabelle' Schema 'import' erstellt. Fertig nach {} Minuten".format(index + 1,
                                                                                                              time_elapsed))
    print("")


def imposm_import():
    start_time0 = time.time()

    pbf_download()
    print("---> Starte Imposm Import")
    print("")

    args = import_config(config_file, "imposm_import", "cmd")
    print(args)
    cmd = subprocess.Popen(args, shell=True)
    cmd.communicate()
    # print(cmd.returncode)
    time_elapsed0 = round((time.time() - start_time0) / 60)
    print("---> Imposm Import in Tabelle 'Mauttabelle' Schema 'import' fertig nach {} Minuten".format(time_elapsed0))
    print("")


def postgis_processing():
    start_time2 = time.time()
    print("---> Starte PostGIS processing")
    print("")

    step1 = import_config(config_file, "sql_files", "step1")
    step2 = import_config(config_file, "sql_files", "step2")

    sqlfile_exectute(step1)
    sqlfile_exectute(step2)

    time_elapsed2 = round((time.time() - start_time2) / 60)
    print("---> PostGIS processing fertig nach {} Minuten".format(time_elapsed2))
    print("")


if __name__ == "__main__":
    start_time3 = time.time()
    update_mautabelle()
    # imposm_import()
    postgis_processing()

    time_elapsed3 = round((time.time() - start_time3) / 60)
    print("---> TollMap Import fertig nach {} Minuten".format(time_elapsed3))
    print("")
