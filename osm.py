from osmapi import OsmApi
from config_importer import import_config

user = import_config("./config.txt", "osm_credentials", "user")
password = import_config("./config.txt", "osm_credentials", "password")
print(user, password)

#api = OsmApi(api="http://api06.dev.openstreetmap.org", username = "kannnixtunix", password = "Abitalismus!1o", changesetauto=True)
api = OsmApi(api="http://api06.dev.openstreetmap.org", username = "kannnixtunix", password = "Abitalismus!1o", changesetauto=True)

'''
#api = OsmApi(api="api06.dev.openstreetmap.org", username=user, passwordfile=password, changesetauto=True, changesetautotags={"comment":u"changeset auto"})

lat = 52.534395
lon = 13.358543

changeset ={u"comment": u"My first test"}
node = {u"lat":lat, u"lon":lon, u"tag":{}}

api.ChangesetCreate(changeset)

api.NodeCreate(node)
api.flush() # to send last updates
api.ChangesetClose()
'''

api.ChangesetCreate({u"comment": u"My first test"})
print(api.NodeCreate({u"lon":1, u"lat":1, u"tag": {"tollmap": "test1"}}))
# {u'changeset': 532907, u'lon': 1, u'version': 1, u'lat': 1, u'tag': {}, u'id': 164684}
api.ChangesetClose()