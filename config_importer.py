import configparser

def import_config(file, section, key):

    configParser = configparser.RawConfigParser()
    configFilePath = file
    configParser.read(configFilePath)
    config = configParser.get(section, key)

    return config