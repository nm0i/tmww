#!/usr/bin/env python2.7

# this file is part of tmww
# willee, 2014, GPL v3

# ip.py - check known player ids and ips for intersecting domains

# ./ip.py /path/to/dbplayers.jsonl < input > domains
# where input data consists of lines of 2 fields:
# 1st field -- id
# 2nd field -- ip

import json, sys

class domain(object):
    def __init__(self):
        self.ids = []
        self.nids = []
        self.players = []
        self.ips = []

    def to_JSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True)

def prepare_domains(altsdb, d):
    with open(altsdb) as db:
        while True:
            i = db.readline()
            if not i:
                break
            t = json.loads(i)
            dom = domain()
            if "accounts" in t:
                dom.nids = t["accounts"]
                dom.players = [ t["player"] ]
                d.append(dom)

def search(d, field, value):
    if field == "ids":
        for i in d:
            if (value in i.ids) or (value in i.nids):
                return d.index(i)
    elif field == "ips":
        for i in d:
            if value in i.ips:
                return d.index(i)

def merge(d, i1, i2):
    d[i1].ids += d[i2].ids
    d[i1].nids += d[i2].nids
    d[i1].players += d[i2].players
    d[i1].ips += d[i2].ips
    del d[i2]

def form_domain(d,id,ip):
    id_domain = search(d, "ids", id)
    ip_domain = search(d, "ips", ip)
    if id_domain is None and ip_domain is None:
        t = domain()
        t.ids.append(id)
        t.ips.append(ip)
        d.append(t)
    elif id_domain is None and ip_domain is not None:
        if id not in d[ip_domain].ids:
            d[ip_domain].ids.append(id)
    elif id_domain is not None and ip_domain is None:
        if ip not in d[id_domain].ips:
            d[id_domain].ips.append(ip)
    else:
        if not (id_domain == ip_domain):
            merge(d, id_domain, ip_domain)

if __name__ == "__main__":
    domains = []

    # altsdb full path
    altsdb = sys.argv[1]
    
    # generate domains for known ids based on altsdb
    prepare_domains(altsdb, domains)

    # generate domains from stdin (login.log expected)
    for line in sys.stdin:
        i = line.split()
        if len(i) != 2:
            continue
        form_domain(domains,i[0],i[1])

    # put on stdout result JSONlines
    # filter non-informative domains
    for i in domains:
        if (not i.ids) and (len(i.players) < 2):
            continue
        print i.to_JSON()

