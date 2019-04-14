import main
import config_importer
import subprocess
args = config_importer.import_config("imposm_import", "cmd")
print(args)

#args = ["/home/david/ba/imposm_0.6.0/imposm", "import", "-config", "/home/david/ba/imposm_0.6.0/config_test.json", "-read", "/home/david/ba/pbf/germany-latest.osm.pbf", "-write"]
#subprocess.Popen(args, shell=True)

#cmd = subprocess.Popen("/home/david/ba/imposm_0.6.0/imposm import -config /home/david/ba/imposm_0.6.0/config.json -read /home/david/ba/pbf/germany-latest.osm.pbf -write", shell=True)
cmd = subprocess.Popen(args, shell=True)

cmd.communicate()
print(cmd.returncode)

#main.imposm_import()
