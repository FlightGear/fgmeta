#!/usr/bin/python

import os, sys, re, glob
import hashlib # for MD5
import subprocess
import shutil # for copy2
import catalogTags
import sgprops
#from multiprocessing import Pool
import argparse
import urllib2

import svn_catalog_repository
import git_catalog_repository
import git_discrete_repository

parser = argparse.ArgumentParser()
parser.add_argument("--clean", help="Regenerate every package", type=bool)
parser.add_argument("dir", help="Catalog directory")
args = parser.parse_args()

standardTagSet = frozenset(catalogTags.tags)
def isNonstandardTag(t):
    return t not in standardTagSet

thumbnailNames = ["thumbnail.png", "thumbnail.jpg"]
includePaths = []

class VariantData:
    def __init__(self, path, node):
        #self._primary = primary
        self._path = path
        self._name = node.getValue("sim/description")

        # ratings

        # seperate thumbnails

    @property
    def catalogNode(self):
        n = sgprops.Node("variant")
        n.addChild("id").value = self._path
        n.addChild("name").value = self._name

class PackageData:
    def __init__(self, path):
        self._path = path
        self._previousSCMRevision = None
        self._previousRevision = 0
        self._thumbnails = []
        self._variants = {}
        self._revision = 0
        self._md5 = None
        self._fileSize = 0

        self._node = sgprops.Node("package")
        self._node.addChild("id").value = self.id

    def setPreviousData(self, node):
        self._previousRevision = node.getValue("revision")
        self._previousMD5 = node.getValue("md5")
        self._previousSCMRevision = node.getValue("scm-revision")
        self._fileSize = int(node.getValue("file-size-bytes"))

    @property
    def id(self):
        return os.path.basename(self._path)

    @property
    def thumbnails(self):
        return self._thumbnails

    @property
    def path(self):
        return self._path

    @property
    def variants(self):
        return self._variants

    @property
    def scmRevision(self):
        currentRev = scmRepo.scmRevisionForPath(self._path)
        if (currentRev is None):
            raise RuntimeError("Unable to query SCM revision of files")

        return currentRev

    def isSourceModified(self, scmRepo):
        if (self._previousSCMRevision == None):
            return True

        if (self._previousSCMRevision == self.scmRevision):
            return False

        return True

    def scanSetXmlFiles(self, includes):
        foundPrimary = False
        foundMultiple = False

        for f in os.listdir(self._path):
            if not f.endswith("-set.xml"):
                continue

            p = os.path.join(self._path, f)
            node = sgprops.readProps(p, includePaths = includes)
            if not node.hasChild("sim"):
                continue

            simNode = node.getChild("sim")
            if (simNode.getValue("exclude", False)):
                continue

            primary = simNode.getValue("variant-of", None)
            if primary:
                if not primary in self.variants:
                    self._variants[primary] = []
                self._variants[primary].append(VariantData(self, node))
                continue

            if foundPrimary:
                if not foundMultiple:
                    print "Multiple primary -set.xml files at:" + self._path
                    foundMultiple = True
                continue
            else:
                foundPrimary = True;

            self.parsePrimarySetNode(simNode)

            for n in thumbnailNames:
                if os.path.exists(os.path.join(self._path, n)):
                    self._thumbnails.append(n)

        if not foundPrimary:
            raise RuntimeError("No primary -set.xml found at:" + self._path)



    def parsePrimarySetNode(self, sim):

        # basic / mandatory values
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
                    print "Skipping non-standard tag:", c.value, self.path
                else:
                    self._node.addChild('tag').value = c.value

        for t in sim.getChildren("thumbnail"):
            self._thumbnails.append(t.value)

    def validate(self):
        for t in self._thumbnails:
            if not os.path.exists(os.path.join(self._path, t)):
                raise RuntimeError("missing thumbnail:" + t);

    def generateZip(self, outDir):
        self._revision = self._previousRevision + 1

        zipName = self.id + ".zip"
        zipFilePath = os.path.join(outDir, zipName)

        os.chdir(os.path.dirname(self.path))

        print "Creating zip", zipFilePath
        # TODO: exclude certain files
        # anything we can do to make this faster?
        subprocess.call(['zip', '--quiet', '-r', zipFilePath, self.id])

        zipFile = open(zipFilePath, 'r')
        self._md5 = hashlib.md5(zipFile.read()).hexdigest()
        self._fileSize = os.path.getsize(zipFilePath)

    def useExistingCatalogData(self):
        self._md5 = self._previousMD5

    def packageNode(self, mirrorUrls, thumbnailUrl):
        self._node.getChild("md5", create = True).value = self._md5
        self._node.getChild("file-size-bytes", create = True).value = self._fileSize
        self._node.getChild("revision", create = True).value = int(self._revision)
        self._node.getChild("scm-revision", create = True).value = self.scmRevision

        for m in mirrorUrls:
            self._node.addChild("url").value = m + "/" + self.id + ".zip"

        for t in self._thumbnails:
            self._node.addChild("thumbnail").value = thumbnailUrl + "/" + self.id + "_" + t

        for pr in self._variants:
            for vr in self._variants[pr]:
                self._node.addChild(vr.catalogNode)

        return self._node

    def extractThumbnails(self, thumbnailDir):
        for t in self._thumbnails:
            fullName = self.id + "_" + t
            shutil.copy2(os.path.join(self._path, t),
                         os.path.join(thumbnailDir, fullName)
                         )
            # TODO : verify image format, size and so on

def scanPackages(globPath):
    result = []
    print "Scanning", globPath
    print os.getcwd()
    for d in glob.glob(globPath):
        # check dir contains at least one -set.xml file
        if len(glob.glob(os.path.join(d, "*-set.xml"))) == 0:
            print "no -set.xml in", d
            continue

        result.append(PackageData(d))

    return result

def initScmRepository(node):
    scmType = node.getValue("type")
    if (scmType == "svn"):
        svnPath = node.getValue("path")
        return svn_catalog_repository.SVNCatalogRepository(svnPath)
    elif (scmType == "git"):
        gitPath = node.getValue("path")
        usesSubmodules = node.getValue("uses-submodules", False)
        return git_catalog_repository.GitCatalogRepository(gitPath, usesSubmodules)
    elif (scmType == "git-discrete"):
        return git_discrete_repository.GitDiscreteSCM(node)
    elif (scmType == None):
        raise RuntimeError("No scm/type defined in catalog configuration")
    else:
        raise RuntimeError("Unspported SCM type:" + scmType)

def processUpload(node, outputPath):
    if not node.getValue("enabled", True):
        print "Upload disabled"
        return

    uploadType = node.getValue("type")
    if (uploadType == "rsync"):
        subprocess.call(["rsync", node.getValue("args", "-az"), ".",
            node.getValue("remote")],
        cwd = outputPath)
    elif (uploadType == "rsync-ssh"):
        subprocess.call(["rsync", node.getValue("args", "-azve"),
            "ssh", ".",
            node.getValue("remote")],
            cwd = outputPath)
    elif (uploadType == "scp"):
        subprocess.call(["scp", node.getValue("args", "-r"), ".",
            node.getValue("remote")],
            cwd = outputPath)
    else:
        raise RuntimeError("Unsupported upload type:" + uploadType)

# dictionary
packages = {}

rootDir = args.dir
if not os.path.isabs(rootDir):
    rootDir = os.path.abspath(rootDir)
os.chdir(rootDir)

configPath = 'catalog.config.xml'
if not os.path.exists(configPath):
    raise RuntimeError("no config file found at:" + configPath)

config = sgprops.readProps(configPath)

# out path
outPath = config.getValue('output-dir')
if outPath is None:
    # default out path
    outPath = os.path.join(rootDir, "output")
elif not os.path.isabs(outPath):
    outPath = os.path.join(rootDir, "output")

if args.clean:
    print "Cleaning output"
    shutil.rmtree(outPath)

if not os.path.exists(outPath):
    os.mkdir(outPath)

thumbnailPath = os.path.join(outPath, config.getValue('thumbnail-dir', "thumbnails"))
if not os.path.exists(thumbnailPath):
    os.mkdir(thumbnailPath)

thumbnailUrl = config.getValue('thumbnail-url')

for i in config.getChildren("include-dir"):
    if not os.path.exists(i.value):
        print "Skipping missing include path:", i.value
        continue
    includePaths.append(i.value)

mirrorUrls = []

# contains existing catalog
existingCatalogPath = os.path.join(outPath, 'catalog.xml')

scmRepo = initScmRepository(config.getChild('scm'))

# scan the directories in the aircraft paths
for g in config.getChildren("aircraft-dir"):
    for p in scanPackages(g.value):
        packages[p.id] = p

if not os.path.exists(existingCatalogPath):
    try:
    # can happen on new or from clean, try to pull current
    # catalog from the upload location
        response = urllib2.urlopen(config.getValue("template/url"), timeout = 5)
        content = response.read()
        f = open(existingCatalogPath, 'w' )
        f.write( content )
        f.close()
    except urllib2.URLError as e:
        print "Downloading current catalog failed", e


if os.path.exists(existingCatalogPath):
    try:
        previousCatalog = sgprops.readProps(existingCatalogPath)
    except:
        print "Previous catalog is malformed"
        previousCatalog = sgprops.Node()

    for p in previousCatalog.getChildren("package"):
        pkgId = p.getValue("id")
        if not pkgId in packages.keys():
            print "Orphaned old package:", pkgId
            continue

        packages[pkgId].setPreviousData(p)
else:
    print "No previous catalog"

catalogNode = sgprops.Node("catalog")
sgprops.copy(config.getChild("template"), catalogNode)

mirrorUrls = (m.value for m in config.getChildren("mirror"))

packagesToGenerate = []
for p in packages.values():
    p.scanSetXmlFiles(includePaths)

    if (p.isSourceModified(scmRepo)):
        packagesToGenerate.append(p)
    else:
        p.useExistingCatalogData()


# def f(x):
#     x.generateZip(outPath)
#     x.extractThumbnails(thumbnailPath)
#     return True
#
# p = Pool(8)
# print(p.map(f,packagesToGenerate))

for p in packagesToGenerate:
   p.generateZip(outPath)
   p.extractThumbnails(thumbnailPath)

print "Creating catalog"
for p in packages.values():
    catalogNode.addChild(p.packageNode(mirrorUrls, thumbnailUrl))

catalogNode.write(os.path.join(outPath, "catalog.xml"))

print "Uploading"
if config.hasChild("upload"):
    processUpload(config.getChild("upload"), outPath)