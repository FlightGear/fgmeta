import os, subprocess
import sgprops
import hashlib # for MD5
import shutil # for copy2
import catalogTags

standardTagSet = frozenset(catalogTags.tags)
def isNonstandardTag(t):
    return t not in standardTagSet

thumbnailNames = ["thumbnail.png", "thumbnail.jpg"]

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
    def __init__(self, path, scmRepo):
        self._path = path
        self._scm = scmRepo
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
        currentRev = self._scm.scmRevisionForPath(self._path)
        if (currentRev is None):
            raise RuntimeError("Unable to query SCM revision of files")

        return currentRev

    @property
    def isSourceModified(self):
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
