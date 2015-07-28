#!/usr/bin/python

import os, sys, re, glob
import subprocess
import sgprops
import argparse
import urllib2
import package as pkg

import svn_catalog_repository
import git_catalog_repository
import git_discrete_repository

parser = argparse.ArgumentParser()
parser.add_argument("--clean", help="Regenerate every package",
     action="store_true")
parser.add_argument("--update", help="Update/pull SCM source",
     action="store_true")
parser.add_argument("--no-update", help="Disable updating from SCM source",
     action="store_true")
parser.add_argument("dir", help="Catalog directory")
args = parser.parse_args()

includePaths = []

def scanPackages(globPath):
    result = []
    print "Scanning", globPath
    print os.getcwd()
    for d in glob.glob(globPath):
        # check dir contains at least one -set.xml file
        if len(glob.glob(os.path.join(d, "*-set.xml"))) == 0:
            print "no -set.xml in", d
            continue

        result.append(pkg.PackageData(d))

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
if args.update or (not args.no-update and scmRepo.getValue("update")):
    scmRepo.update()

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
    catalogNode.addChild(p.packageNode(scmRepo, mirrorUrls, thumbnailUrl))

catalogNode.write(os.path.join(outPath, "catalog.xml"))

print "Uploading"
for up in config.getChildren("upload"):
    processUpload(up, outPath)
