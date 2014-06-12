#!/usr/bin/python

import os, sys, re
import urllib
import hashlib # for MD5

import catalogFilenames
import catalogTags
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
    
standardTagSet = frozenset(catalogTags.tags)
def isNonstandardTag(t):
    return t not in standardTagSet
    
# create the download cache dir if require

cacheDir = '.catalog_cache'
if not os.path.isdir(cacheDir):
    print "Creating catalog cache dir"
    os.mkdir(cacheDir)
    
    
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
                if isNonstandardTag(c.value):
                    print "Skipping non-standard tag:", c.value
                else:
                    pkgNode.addChild('tag').value = c.value
                
        # create download and thumbnail URLs
        s = "{url}Aircraft-3.0/"
        if d not in catalogFilenames.aircraft:
            print "filename not found for:",d
            raise RuntimeError("filename not found for:" + d)
        s += catalogFilenames.aircraft[d]
        
        for u in urls:
            pkgNode.addChild("url").value = s.format(url=u)
        
        for t in thumbs:
            pkgNode.addChild("thumbnail").value = t.format(acft=d)
        
        cachedZip = os.path.join(cacheDir, catalogFilenames.aircraft[d])
        if not os.path.exists(cachedZip):
            # download the zip
            url = s.format(url=urls[0])
            print "Downloading ", url
            urllib.urlretrieve(url, cachedZip)
        #else:
        #    print "Using cached zip for", d
            
        zipFile = open(cachedZip, 'r')
        
        digest = hashlib.md5(zipFile.read()).hexdigest()
        pkgNode.addChild("md5").value = digest
        pkgNode.addChild("file-size-bytes").value = os.path.getsize(cachedZip)
    except:
        print "Failure processing:", setFilePath
        
catalogProps.write("catalog.xml")        