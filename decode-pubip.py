import json, sys

#f = open("res.json", 'r')
#j = json.load(f)
j = json.load(sys.stdin)
for attr in j: 
    if attr.get('Role')=='DS':
        print (attr.get('IPAddress'))
