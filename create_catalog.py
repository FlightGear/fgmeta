#!/usr/bin/python

import os
import sys
import fnmatch
import tarfile
import hashlib
import shutil

import xml.etree.cElementTree as ET

rootPath = sys.argv[1]
outputDir = sys.argv[2]

existingCatalogPath = os.path.join(outputDir, 'catalog.xml')
existingCatalog = None
if os.path.exists(existingCatalogPath):
    existingCatalogPath = ET.parse(existingCatalogPath)

for file in os.listdir(outputDir):
    if fnmatch.fnmatch(file, '*.tar.gz'):
        os.remove(os.path.join(outputDir, file));


thumbsDir = os.path.join(outputDir, 'thumbs')
shutil.rmtree(thumbsDir)
os.makedirs(thumbsDir)

def setProperty(node, id, value):
    s = ET.SubElement(node, id)
    s.text = value

def parse_setXml(path):
    tree = ET.parse(path)
    
    desc = tree.find('sim/description')
    ratings = tree.find('sim/rating')
    if (ratings is not None):
        for rating in list(ratings):
            if rating.tag == 'status':
                continue
                
            rvalue = int(rating.text)
            if rvalue < 2:
                return None
    else:
        return None
    
    d = {}
    
    d['desc'] = desc
    d['ratings'] = ratings;
    d['status'] = tree.find('sim/status')
    d['authors'] = tree.findall('sim/author')

    return d
    
def process_aircraft(acft, path):
    print '===' + acft + '==='
    setFiles = []
    thumbs = []
    
    for file in os.listdir(path):
        if fnmatch.fnmatch(file, '*-set.xml'):
            setFiles.append(file);
        
        if fnmatch.fnmatch(file, 'thumbnail*'):
            thumbs.append(file)
    
    aircraft = []
    for s in setFiles:
        d = parse_setXml(os.path.join(path, s))
        if d is None:
            continue
        
        d['set'] = s[0:-8]
        aircraft.append(d)
    
    thumbnailNames = []
    # copy thumbnails
    for t in thumbs:
        outThumb = os.path.join(thumbsDir, acft + "-" + t)
        thumbnailNames.append(acft + "-" + t)
        shutil.copyfile(os.path.join(path, t), outThumb)
            
    if len(aircraft) == 0:
        print "no aircraft profiles for " + acft
        return
            
    # tarball creation
    outTar = os.path.join(outputDir, acft + ".tar.gz")
    tar = tarfile.open(outTar, "w:gz")
    tar.add(path, acft)
    tar.close()

    digest = hashlib.md5(open(outTar, 'r').read()).hexdigest()
    revision = 1
    
    # revision check
    if acft in existingPackages:
        previousMd5 = existingPackages[acft].find('md5').text
        previousRevsion = int(existingPackages[acft].find('revision').text)
        if digest != previousMd5:
            print acft + ": MD5 has changed"
            revision = previousRevsion + 1
    else:    
        existingPackages[acft] = ET.Element('package')
        
    setProperty(existingPackages[acft], 'id', acft)
    setProperty(existingPackages[acft], 'revision', str(revision))
    setProperty(existingPackages[acft], 'md5', digest)
    setProperty(existingPackages[acft], 'description', aircraft[0]['desc'])
    
    #setProperty(existingPackages[acft], 'thumbnails', thumbnailNames)
    
    for t in thumbnailNames:
        tn = ET.SubElement(existingPackages[acft], 'thumbnail')
        tn.text = 'thumbs/' + t
        
    existingPackages[acft].append(aircraft[0]['ratings'])
    
    print "wrote tarfile, digest is " + digest
    
root = ET.Element('PropertyList')
catalogTree = ET.ElementTree(root)

existingPackages = dict()

if (existingCatalog is not None):
    print 'have existing catalog data'
    
    root.append(existingCatalog.find('license'))
    root.append(existingCatalog.find('url'))
    root.append(existingCatalog.find('description'))
    root.append(existingCatalog.find('id'))
    
    # existing data (for revision incrementing)
    for n in existingCatalog.findall('package/id'):
        existingPackages[n.text] = n;
        
#licenseElement = ET.SubElement(root, 'license')
#licenseElement.text = 'gpl'

#urlElement = ET.SubElement(root, 'url')
#urlElement.text = 'http://catalog.xml'

for acft in os.listdir(rootPath):
    path = os.path.join(rootPath, acft);
    if (os.path.isdir(path)):
        process_aircraft(acft, path)


for ep in existingPackages:
    root.append(existingPackages[ep])

catalogTree.write(os.path.join(outputDir, 'catalog.xml'), 'UTF-8')

