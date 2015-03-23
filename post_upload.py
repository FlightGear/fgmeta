#!/usr/bin/python

import os, sys, re, fnmatch
from subprocess import call

suffix = '.dmg'
if sys.argv[1] == 'windows':
    suffix = '.exe'
    
allSuffix = '*' + suffix

print "Wildcard pattern is:" + allSuffix
    
pattern = r'FlightGear-(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)-([\w-]+)' + suffix
publicNightlyRoot = "/var/www/html/builds/nightly"
incomingDir = "/home/jenkins/nightly-incoming"
sourceForgePath = "/home/frs/project/f/fl/flightgear/unstable/"
sourceForgeUserHost = "jmturner@frs.sourceforge.net"
sftpCommandFile = "sftp-commands"

os.chdir(publicNightlyRoot)

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
        newFiles.append(file)
        
# copy and symlink
for file in newFiles:        
    # move it to the public location
    srcFile = os.path.join(incomingDir, file)
    os.rename(srcFile, file)
    
    # symlink for stable web URL
    m = re.match(r'FlightGear-\d+\.\d+\.\d+-([\w-]+)' + suffix, file)
    latestName = 'FlightGear-latest-' + m.group(1) + suffix
    
    if os.path.exists(latestName):
        os.remove(latestName)
    os.symlink(file, latestName)
        
# remove files from SF
if len(oldFiles) > 0:
    f = open(sftpCommandFile, 'w')
    f.write("cd " + sourceForgePath + '\n')
    for file in oldFiles:
        print "Removing file " + file + " from SourceForge"
        f.write("rm " + file + '\n')
    f.write("bye\n")
    f.close()
    
    call(["sftp", "-b", sftpCommandFile, sourceForgeUserHost])
    os.remove(sftpCommandFile)
    
# upload to SourceForge
for file in newFiles: 
    print "Uploading " + file + " to SourceForge"
    call(["scp", file, sourceForgeUserHost + ":" + sourceForgePath + file])
        
        