#!/usr/bin/python

import os, sys, re, glob
import hashlib # for MD5
import subprocess

import catalogTags
import sgprops

import svn_catalog_repository
import git_catalog_repository
import git_discrete_repository

# TODO
# uploading / rsyncing 

class VariantData:
    def __init__(self, primary, path, node):
        self._primary = primary
        self._path = path
        self._name = node.getValue("sim/description")
        
        # ratings
        
        # seperate thumbnails
        
    @property
    def catalogNode(self):
        n = Node("variant")
        n.addChild("id") = path
        m.addChild("name") = self._name
        
class PackageData:
    def __init__(path):
        self._path = path
        self._previousSCMRevision = None
        self._previousRevision = 0
        self._thumbnails = []
        self._variants = {}
        
        self._node = sgprops.Node()
        self._node.addChild("id").value = self.id
        
    def setPreviousData(node):
        self._previousRevision = node.getValue("revision")
        self._previousMD5 = node.getValue("md5")
        self._previousSCMRevision = node.getValue("scm-revision")
    
    @property
    def id(self):
        return os.path.basename(self._path)
    
    @property
    def thumbnails(self):
        return self._thumbnails
        
    def isSourceModified(self, scmRepo):
        if (self._previousSCMRevision == None):
            return True
            
        currentRev = scmRepo.scmRevisionForPath(self._path)
        if (currentRev is None):
            raise RuntimeError("Unable to query SCM revision of files")
            
        if (self._previousSCMRevision == currentRev):
            self._scm = self._previousSCMRevision
            return False
            
        self._scm = currentRev
        return True
        
    def scanSetXmlFiles(self):
        foundPrimary = False
        
        for f in os.listdir(self._path):
            if !f.endswith("-set.xml"):
                continue
                
            p = os.path.join(self._path, f)
            node = readProps(p)
            simNode = node.getChild("sim")
            if (simNode.getValue("exclude")):
                continue
                
            if primary = simNode.getValue("variant-of", None):
                if not primary in variants:
                    self._variants[primary] = []
                self._variants[primary].append(VariantData(self, node))
                continue
            
            if foundPrimary:
                print "Multiple primary -set.xml files at:" + self._path
                continue
            else:
                foundPrimary = True;
                
            parsePrimarySetNode(simNode)
            
            if os.path.exists(os.path.join(self._path, "thumbnail.png")):
                self._thumbnails.append("thumbnail.png")
            
        if not foundPrimary:
            raise RuntimeError("No primary -set.xml found at:" + self._path)
            
        
        
    def parsePrimarySetNode(self, sim):
        
        # basic / mandatory values
        self._node.addChild('id').value = d
        self._node.addChild('name').value = sim.getValue('description')
        
        longDesc = sim.getValue('long-description')
        if longDesc is not None:
            self._node.addChild('description').value = longDesc
            
        # copy all the standard values
        for p in ['status', 'author', 'license']:
            v = sim.getValue(p)
            if v is not None:
                self._node.addChild(p).value = v
            
        # ratings
        if sim.hasChild('rating'):
            pkgRatings = self._node.addChild('rating')
            for r in ['FDM', 'systems', 'cockpit', 'model']:
                pkgRatings.addChild(r).value = sim.getValue('rating/' + r, 0)
            
        # copy tags
        if sim.hasChild('tags'):
            for c in sim.getChild('tags').getChildren('tag'):
                if isNonstandardTag(c.value):
                    print "Skipping non-standard tag:", c.value
                else:
                    self._node.addChild('tag').value = c.value
                    
        self._thumbnails = (t.value for t in self.getChildren("thumbnail"))
        
    def validate(self):
        for t in self._thumbnails:
            if not os.path.exists(os.path.join(self._path, t)):
                raise RuntimeError("missing thumbnail:" + t);
        
    def generateZip(self, outDir):
        self._revision = self._previousRevision + 1
        
        zipName = self.id
        zipFilePath = os.path.join(outDir, zipName)
        
        # TODO: exclude certain files
        subprocess.call(['zip', '-r', self.path, zipFilePath])
        
        zipFile = open(zipFilePath + ".zip", 'r')
        self._md5 = hashlib.md5(zipFile.read()).hexdigest()
        self._fileSize = os.path.getsize(zipFile)
        
    @property
    def catalogNode(self, mirrorUrls, thumbnailUrl):
        self._node.getChild("md5", create = True).value = self._md5
        self._node.getChild("file-size-bytes", create = True).value = self._fileSize
        self._node.addChild("revision", create = True).value = self._revision
        self._node.addChild("scm-revision", create = True).value = self._scm
        
        for m in mirrorUrls:
            self._node.addChild("url", m + "/" + self.id + ".zip")
            
        for t in self._thumbnails:
            self._node.addChild("thumbnail", thumbnailUrl + "/" + self.id + "_" + t)
        
        for pr in self._variants:
            for vr in self._variants[pr]:
                self._node.addChild(vr.catalogNode)
        
        return self._node
        
    def extractThumnbails(self, thumbnailDir):
        for t in self._thumbnails:
            fullName = self.id + "_" + t
            os.file.copy(os.path.join(self._path, t),
                         os.path.join(thumbnailDir, fullName)
                         )
            # TODO : verify image format, size and so on
        
def scanPackages(globPath):
    result = []
    for d = in glob.glob(globPath):
        result.append(PackageData(d))
    
    return result

def initScmRepository(node):
    scmType = node.getValue("type")
    if (scmType == "svn"):
        svnPath = node.getValue("path")
        return SVNCatalogRepository(svnPath)
    else if (scmType == "git"):
        gitPath = node.getValue("path")
        usesSubmodules = node.getValue("uses-submodules", False)
        return GitCatalogRepository(gitPath, usesSubmodules)
    else if (scmType == "git-discrete")
        return GitDiscreteSCM(node)
    else if (scmType == None):
        raise RuntimeError("No scm/type defined in catalog configuration")
    else:
        raise RuntimeError("Unspported SCM type:" + scmType)
    
def processUpload(node, outputPath):
    uploadType = node.getValue("type")
    if (type == "rsync"):
        subprocess.call(["rsync", node.getValue("args", "-az"), ".", 
            node.getValue("remote")],
        cwd = outputPath)
    else if (type == "scp"):
        subprocess.call(["scp", node.getValue("args", "-r"), outputPath,
            node.getValue("remote")])
    else:
        raise RuntimeError("Unsupported upload type:" + uploadType)

# dictionary    
packages = {}

rootDir = sys.argv[1]
os.path.chdir(rootDir)

configPath = 'catalog.config.xml'
if !os.path.exists(configPath):
    raise RuntimeError("no config file found at:" + configPath)
    
config = readProps(configPath)

# out path
outPath = config.getValue('output-dir')
if outPath is None:
    # default out path
    outPath = "output"
    
print "Output path is:" + outPath

thumbnailPath = os.path.join(outPath, config.getValue('thumbnail-dir', "thumbnails"))

# contains existing catalog
existingCatalogPath = os.path.join(outPath, 'catalog.xml')

scmRepo = initScmRepository(config.getChild('scm'))

# scan the directories in the aircraft paths
for g in config.getChildren("aircraft-dir"):     
    for p in scanPackages(g):
        packages[p.id] = p

previousCatalog = readProps(existingCatalogPath)
for p in previousCatalog.getChildren("package"):
    pkgId = p.getValue("id")
    if !packages.contains(pkgId):
        print "Orphaned old package:", pkgId
        continue
        
    packages[pkgId].setPreviousData(p)
    

catalogNode = sgprops.Node()

sgprops.copy(config.getChild("template"), catalogNode)

packagesToGenerate = []
for p in packages:
    if (p.isSourceModified(scmRepo)):
        packagesToGenerate.append(p)
    
for p in packagesToGenerate:
    p.generateZip(outPath)
    p.extractThumbnails(thumbnailPath)
    catalogNode.addChild(p.catalogNode)
    
if config.hasChild("upload"):
    processUpload(config.getChild("upload"), outPath)