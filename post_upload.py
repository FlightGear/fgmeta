#!/usr/bin/python

# this file runs on the download server (download.flightgear.org)
# from the Jenkins upload-via-ssh jobs. It ensures that only complete
# uploads are visible (and mirrored to SF).

import os, sys, re, fnmatch
from subprocess import call

suffixes = ['dmg']

release_version = "unknown"

if sys.argv[1] == 'windows':
    suffixes = ['exe']
if sys.argv[1] == 'linux':
    suffixes = ['tar.bz2', 'tar.xz', 'txz', 'AppImage']

isRelease = False
if len(sys.argv) > 2 and sys.argv[2] == 'release':
    isRelease = True

if len(sys.argv) > 3:
    release_version = sys.argv[3]

print "are we doing an RC:" + str(isRelease)

sys.stdout.flush()

sourceForgeUserHost = "jmturner@frs.sourceforge.net"
sftpCommandFile = "sftp-commands"
symbolDir = "/home/jenkins/symbols"

if isRelease:
    publicRoot = "/var/www/downloads/builds/rc"
    incomingDir = "/home/jenkins/incoming"
    sourceForgePath = "/home/frs/project/f/fl/flightgear/release-" + release_version + "/"
else:
    publicRoot = "/var/www/downloads/builds/nightly"
    incomingDir = "/home/jenkins/nightly-incoming"
    sourceForgePath = "/home/frs/project/f/fl/flightgear/unstable/"

os.chdir(publicRoot)

def matchVersionWithSuffix(suffix, file):
    pattern = r'\w+-(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)([\w-]*)\.' + suffix
    m = re.match(pattern, file)
    if (m is None):
        return None
    return (m.group('major'), m.group('minor'), m.group('patch'))

def findFileVersion(dir):
    for file in os.listdir(dir):
        for suffix in suffixes:
            if file.endswith(suffix):
                v = matchVersionWithSuffix(suffix, file)
                if v:
                    return v

    return None

incomingVer = findFileVersion(incomingDir)
if incomingVer is None:
    print "No incoming files found matching suffixes:" + ', '.join(suffixes)
    exit()

existingVer = findFileVersion('.')

# if files in dest location mis-match the version, archive them
# and re-create the symlinks

versionChange = (existingVer != incomingVer)

oldFiles = []
incomingFiles = []
newFiles = []

# remove all files matching a suffix in the current director
# record removed files (except symlinks) in global-var 
# oldFiles, so we could also remove them from SourceForge
def removeFilesMatching(suffix):
    for file in os.listdir('.'):
        if not fnmatch.fnmatch(file, '*' + suffix):
            continue

        if not os.path.islink(file):
            oldFiles.append(file)
        os.remove(file)

if versionChange:
    print "Version number changing"
    for suffix in suffixes:
        removeFilesMatching(suffix)

    if (sys.argv[1] == 'windows'):
        removeFilesMatching('.pdb')
                

# collecting incoming files
for file in os.listdir(incomingDir):
    for suffix in suffixes:
        if file.endswith(suffix):
            incomingFiles.append(file)

    if (sys.argv[1] == 'windows') and fnmatch.fnmatch(file, "*.pdb"):
        # manually copy PDBs, don't add to incoming files
        srcFile = os.path.join(incomingDir, file)
        os.rename(srcFile, file)
        newFiles.append(file)

print "Incoming files:" + ', '.join(incomingFiles)

# copy and symlink
for file in incomingFiles:
    # move it to the public location
    srcFile = os.path.join(incomingDir, file)

    outFile = file
    # insert -rc before file extension
    if isRelease:
        m = re.match(r'(\w+-\d+\.\d+\.\d+[\w-]*)\.(.*)', file)
        outFile = m.group(1) + '-rc.' + m.group(2)
        print "RC out name is " + outFile

    os.rename(srcFile, outFile)
    newFiles.append(outFile)

    if not isRelease:
        # symlink for stable web URL
        m = re.match(r'(\w+)-\d+\.\d+\.\d+(-[\w-]+)?\.(.*)' , file)

        if m.group(2):
            latestName = m.group(1) + '-latest' + m.group(2) + '.' + m.group(3) 
        else:
            latestName = m.group(1) + '-latest.' + m.group(3) 

        print "Creating symlink from " + file + " to " + latestName
        if os.path.exists(latestName):
            print "\tremoving existing target"
            os.remove(latestName)
        os.symlink(file, latestName)

# remove files from SF
#if len(oldFiles) > 0:
#    f = open(sftpCommandFile, 'w')
#    f.write("cd " + sourceForgePath + '\n')
#    for file in oldFiles:
#        print "Removing file " + file + " from SourceForge"
#        f.write("rm " + file + '\n')
#    f.write("bye\n")
#    f.close()
#
#    call(["sftp", "-b", sftpCommandFile, sourceForgeUserHost])
#    os.remove(sftpCommandFile)

# upload to SourceForge
# for file in newFiles:
#     print "Uploading " + file + " to SourceForge"
#     print "Skipped until SF FRS is fixed"
# #    sys.stdout.flush()
# #    call(["scp", "-v", file, sourceForgeUserHost + ":" + sourceForgePath + file])
# #    call(["rsync", "-e", "ssh", file, sourceForgeUserHost + ":" + sourceForgePath + file])
# #    print "...Done"
#     sys.stdout.flush()

