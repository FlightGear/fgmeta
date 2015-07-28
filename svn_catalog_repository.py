
import subprocess, os, sgprops
import xml.etree.cElementTree as ET

class SVNCatalogRepository:
    def __init__(self, node):
        path = node.getValue("path")
        if not os.path.exists(path):
            raise RuntimeError("No directory at:" + path)

        self._path = path
        xml = subprocess.check_output(["svn", "info", "--xml", path])
        root = ET.fromstring(xml)

        if (root.find(".//repository/root") == None):
            raise RuntimeError("Not an SVN repository:" + path)

        self._aircraftPath = None
        if node.hasChild("scan-suffix"):
            self._aircraftPath = os.path.join(path, node.getValue("scan-suffix"))

    @property
    def path(self):
        return self._path

    @property
    def aircraftPath(self):
        return self._aircraftPath

    def hasPathChanged(self, path, oldRevision):
        return self.scmRevisionForPath(path) != oldRevision

    def scmRevisionForPath(self, path):
        xml = subprocess.check_output(["svn", "info", "--xml", path])
        root = ET.fromstring(xml)
        commit = root.find(".//entry/commit")
        return commit.get('revision', 0)

    def update(self):
        print "SVN update of", self._path
        subprocess.call(["svn", "update", self._path])
