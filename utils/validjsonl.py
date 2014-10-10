#!/usr/bin/env python2.7
# https://github.com/Julian/jsonschema
import json, sys
from jsonschema import validate

# FIXME export default schema from tmww?
# schema describing elements of known structure
schema = {
    "type" : "object",
    "properties" : {
        "player" : { "type" : "string" },
        "name" : { "type" : "string" },
        "wiki" : { "type" : "string" },
        "trello" : { "type" : "string" },
        "server" : { "type" : "string" },
        "port" : { "type" : "string" },
        "tmwc" : { "type" : "string" },
        "active" : { "type" : "string" },
        "cc" : { "type" : "string" },
        "forum" : { "type" : "array",
            "items" : { "type" : "string" } },
        "aka" : { "type" : "array",
            "items" : { "type" : "string" } },
        "roles" : { "type" : "array",
            "items" : { "type" : "string" } },
        "alts" : { "type" : "array",
            "items" : { "type" : "string" } },
        "accounts" : { "type" : "array",
            "items" : { "type" : "string" } },
        "links" : { "type" : "array",
            "items" : { "type" : "string" } },
        "xmpp" : { "type" : "array",
            "items" : { "type" : "string" } },
        "mail" : { "type" : "array",
            "items" : { "type" : "string" } },
        "skype" : { "type" : "array",
            "items" : { "type" : "string" } },
        "repo" : { "type" : "array",
            "items" : { "type" : "string" } },
        "tags" : { "type" : "array",
            "items" : { "type" : "string" } },
        "comments" : { "type" : "array",
            "items" : { "type" : "string" } }
    }
}

def validatejsonl(jsonlines):
    with open(jsonlines) as f:
        for data in f:
            # sys.stdout.write(data)
            try:
                validate(json.loads(data),schema)
            except Exception as inst:
                print inst

if __name__ == "__main__":
    validatejsonl(sys.argv[1])

