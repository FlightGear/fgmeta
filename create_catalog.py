#!/usr/bin/python

import os, sys, re

import sgprops

fgRoot = sys.argv[1]
aircraftDir = os.path.join(fgRoot, 'Aircraft')

catalogProps = sgprops.Node()
catalogProps.addChild('version').value = '3.1.0'
catalogProps.addChild('id').value = 'org.flightgear.default'
catalogProps.addChild('license').value = 'GPL'
catalogProps.addChild('url').value = "http://fgfs.goneabitbursar.com/pkg/3.1.0/default-catalog.xml"

catalogProps.addChild('description').value = "Aircraft developed and maintained by the FlightGear project"

de = catalogProps.addChild('de')
# de.addChild('description').value = "<German translation of catalog description>"

fr = catalogProps.addChild('fr')

urls = [
        "http://flightgear.wo0t.de/",
        "http://ftp.icm.edu.pl/packages/flightgear/",
        "http://mirrors.ibiblio.org/pub/mirrors/flightgear/ftp/",
        "http://ftp.igh.cnrs.fr/pub/flightgear/ftp/",
        "http://ftp.linux.kiev.ua/pub/fgfs/",
        "http://fgfs.physra.net/ftp/"
]

thumbs = [
    "http://www.flightgear.org/thumbs/v3.0/{acft}.jpg"
]

for d in os.listdir(aircraftDir):
    acftDirPath = os.path.join(aircraftDir, d)
    if not os.path.isdir(acftDirPath):
        continue
        
    setFilePath = None

    # find the first set file 
    # FIXME - way to designate the primary file
    for f in os.listdir(acftDirPath):
        if f.endswith("-set.xml"):
            setFilePath = os.path.join(acftDirPath, f)
            break
            
    if setFilePath is None:
        print "No -set.xml file found in",acftDirPath,"will be skipped"
        continue
    
    try:
        props = sgprops.readProps(setFilePath, dataDirPath = fgRoot)
        sim = props.getNode("sim")
     
        pkgNode = catalogProps.addChild('package')
        
        # basic / mandatory values
        pkgNode.addChild('id').value = d
        pkgNode.addChild('name').value = sim.getValue('description')
        
        longDesc = sim.getValue('long-description')
        if longDesc is not None:
            pkgNode.addChild('description').value = longDesc
            
        # copy all the standard values
        for p in ['status', 'author', 'license']:
            v = sim.getValue(p)
            if v is not None:
                pkgNode.addChild(p).value = v
            
        # ratings
        if sim.hasChild('rating'):
            pkgRatings = pkgNode.addChild('rating')
            for r in ['FDM', 'systems', 'cockpit', 'model']:
                pkgRatings.addChild(r).value = sim.getValue('rating/' + r, 0)
            
        # copy tags
        if sim.hasChild('tags'):
            for c in sim.getChild('tags').getChildren('tag'):
                pkgNode.addChild('tag').value = c.value
        
        pkgNode.addChild("md5").value = 'ffffffffff'
        
        # create download and thumbnail URLs
        date = '0000000'
        s = "{url}Aircraft-3.0/{acft}_{date}.zip"
        for u in urls:
            pkgNode.addChild("url").value = s.format(url=u,acft=d, date=date)
        
        for t in thumbs:
            pkgNode.addChild("thumbnail").value = t.format(acft=d)
        
    except:
        print "Failure processing:", setFilePath
        

catalogProps.write("catalog.xml")        