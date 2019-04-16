import psycopg2
import psycopg2.extras
from config_importer import import_config


host = import_config("config.txt", "db_config", "host")
db_name = import_config("config.txt", "db_config","dbname")
user = import_config("config.txt", "db_config","user")
password = import_config("config.txt", "db_config","password")
port = import_config("config.txt", "db_config","port")


conn_string ="host='{}' dbname='{}' user='{}' password='{}' port='{}'".format(host, db_name, user, "xxx", port)
#conn_string ="host='localhost' dbname='osm' user='postgres' password='postgres'"
print(conn_string)
print("Datenbankverbindung aufbauen: {}".format(conn_string))
print("")



def sql_execute(sql, values):
    try:
        conn = psycopg2.connect(conn_string)


        cursor = conn.cursor()


        cursor.execute(sql, values)
        rows = cursor

        conn.commit()
        cursor.close()
        conn.close()

        return rows


        ''' if len(rows) != 0:
            print("return rows")
            return rows'''


    except (Exception, psycopg2.DatabaseError) as error:
        print(error)


def sqlfile_exectute(sqlfile):


    try:
        conn = psycopg2.connect(conn_string)

        cursor = conn.cursor()
        sqlfile = open(sqlfile, 'r')
        cursor.execute(sqlfile.read())
        rows = cursor

        conn.commit()
        cursor.close()
        conn.close()

        return rows

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
