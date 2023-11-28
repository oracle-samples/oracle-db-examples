import sys
import re
import sys
import os
import json



def list_schemas(location):
    d = [ x.removeprefix(f'{location}/') for x in [x[0] for x in os.walk(location) if x[0] != location ] ]
    d.remove("admin")
    return json.dumps({"schemas": d})
    

def clean(with_name):
    # used for database name
    return re.sub('[^a-z0-9_$#]', '', with_name)


def get_feature_name(listing):
    # expects list of [x, feature/A102, y]

    for x in listing:
        if x.startswith("feature"):
            return x

def get_identification(from_feature_name):
    # expects identification to be after feature

    listing = from_feature_name.split("/")
    for i in range(len(listing)):
        if listing[i].lower().startswith("feature") and i+1 < len(listing):
            return listing[i+1].lower()


# expects [filename] [command] [inputs]
command = sys.argv[1]

if command == "dbname":
    print(clean(sys.argv[2]))
elif command == "id":
    names = get_feature_name(sys.argv[2:])
    ident = get_identification(names)
    print(ident)
elif command == "schemas":
    print(list_schemas(sys.argv[2]))