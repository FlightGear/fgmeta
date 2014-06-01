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
        "http://flightgear.wo0t.de/Aircraft-3.0/{acft}_20140116.zip",
        "http://ftp.icm.edu.pl/packages/flightgear/Aircraft-3.0/{acft}_20140216.zip",
        "http://mirrors.ibiblio.org/pub/mirrors/flightgear/ftp/Aircraft-3.0/{acft}_20140216.zip",
        "http://ftp.igh.cnrs.fr/pub/flightgear/ftp/Aircraft-3.0/{acft}_20140116.zip",
        "http://ftp.linux.kiev.ua/pub/fgfs/Aircraft-3.0/{acft}_20140116.zip",
        "http://fgfs.physra.net/ftp/Aircraft-3.0/{acft}_20130225.zip"
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
        pkgNode.addChild('id').value = d
        pkgNode.addChild('name').value = sim.getValue('description')
        
        longDesc = sim.getValue('long-description')
        if longDesc is not None:
            pkgNode.addChild('description').value = longDesc
            
        # copy tags
        if sim.hasChild('tags'):
            for c in sim.getChild('tags').getChildren('tag'):
                pkgNode.addChild('tag').value = c.value
        
        # create download and thumbnail URLs
        for u in urls:
            pkgNode.addChild("url").value = u.format(acft=d)
        
        for t in thumbs:
            pkgNode.addChild("thumbnail").value = t.format(acft=d)
        
    except:
        print "Failure processing:", setFilePath
        

catalogProps.write("catalog.xml")        