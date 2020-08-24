#!/usr/bin/python

# this file runs on the download server (download.flightgear.org)
# from the Jenkins upload-via-ssh jobs. It ensures that only complete
# uploads are visible (and mirrored to SF).

import os, sys, re, fnmatch
from subprocess import call

suffix = '.dmg'
release_version = "unknown"

if sys.argv[1] == 'windows':
    suffix = '.exe'
if sys.argv[1] == 'linux':
    suffix = '.tar.bz2'

isRelease = False
if len(sys.argv) > 2 and sys.argv[2] == 'release':
    isRelease = True

if len(sys.argv) > 3:
    release_version = sys.argv[3]

print "Post-upload running: suffix=" +  suffix
print "are we doing an RC:" + str(isReleaseCandidate)

allSuffix = '*' + suffix

print "Wildcard pattern is:" + allSuffix

sys.stdout.flush()

pattern = r'\w+-(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)([\w-]*)' + suffix
sourceForgeUserHost = "jmturner@frs.sourceforge.net"
sftpCommandFile = "sftp-commands"
symbolDir = "/home/jenkins/symbols"

if isRelease:
    publicRoot = "/var/www/html/builds/rc"
    incomingDir = "/home/jenkins/incoming"
    sourceForgePath = "/home/frs/project/f/fl/flightgear/release-" + release_version + "/"
else:
    publicRoot = "/var/www/html/builds/nightly"
    incomingDir = "/home/jenkins/nightly-incoming"
    sourceForgePath = "/home/frs/project/f/fl/flightgear/unstable/"

os.chdir(publicRoot)

def findFileVersion(dir):
    for file in os.listdir(dir):
        if fnmatch.fnmatch(file, allSuffix):
            m = re.match(pattern, file)
            if (m is not None):
                return (m.group('major'), m.group('minor'), m.group('patch'))

    return None

incomingVer = findFileVersion(incomingDir)
if incomingVer is None:
    print "No incoming files found matching " + allSuffix
    exit()

existingVer = findFileVersion('.')

# if files in dest location mis-match the version, archive them
# and re-create the symlinks

versionChange = (existingVer != incomingVer)

oldFiles = []
incomingFiles = []
newFiles = []

if versionChange:
    print "Version number changing"

    for file in os.listdir('.'):
        if fnmatch.fnmatch(file, allSuffix):
            if not os.path.islink(file):
                oldFiles.append(file)
            os.remove(file)

for file in os.listdir(incomingDir):
    if fnmatch.fnmatch(file, allSuffix):
        incomingFiles.append(file)

# copy and symlink
for file in incomingFiles:
    # move it to the public location
    srcFile = os.path.join(incomingDir, file)

    outFile = file
    # insert -rc before suffix
    #if isRelease:
        #m = re.match(r'(\w+-\d+\.\d+\.\d+[\w-]*)' + suffix, file)
        #outFile = m.group(1) + '-rc' + suffix
        #print "RC out name is " + outFile

    os.rename(srcFile, outFile)
    newFiles.append(outFile)

    if not isRelease:
        # symlink for stable web URL
        m = re.match(r'(\w+)-\d+\.\d+\.\d+-([\w-]+)' + suffix, file)
        latestName = m.group(1) + '-latest-' + m.group(2) + suffix

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
for file in newFiles:
    print "Uploading " + file + " to SourceForge"
    print "Skipped until SF FRS is fixed"
#    sys.stdout.flush()
#    call(["scp", "-v", file, sourceForgeUserHost + ":" + sourceForgePath + file])
#    call(["rsync", "-e", "ssh", file, sourceForgeUserHost + ":" + sourceForgePath + file])
#    print "...Done"
    sys.stdout.flush()

if sys.argv[1] == 'windows':
    print "Archiving PDB files"
    for file in os.listdir(incomingDir):
        if fnmatch.fnmatch(file, "*.pdb"):
            srcFile = os.path.join(incomingDir, file)
            outFile = os.path.join(symbolDir, file)
            os.rename(srcFile, outFile)
