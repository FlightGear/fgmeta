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

shutil.rmtree(outputDir)
thumbsDir = os.path.join(outputDir, 'thumbs')
os.makedirs(thumbsDir)

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
            
    # copy thumbnails
    for t in thumbs:
        outThumb = os.path.join(thumbsDir, acft + "-" + t)
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
    print "wrote tarfile, digest is " + digest
    
root = ET.Element('PropertyList')
catalogTree = ET.ElementTree(root)

licenseElement = ET.SubElement(root, 'license')
licenseElement.text = 'gpl'

urlElement = ET.SubElement(root, 'url')
urlElement.text = 'http://catalog.xml'

for acft in os.listdir(rootPath):
    path = os.path.join(rootPath, acft);
    if (os.path.isdir(path)):
        process_aircraft(acft, path)

catalogTree.write(os.path.join(outputDir, 'catalog.xml'), 'UTF-8')

