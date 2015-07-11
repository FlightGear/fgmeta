
import subprocess
import xml.etree.cElementTree as ET

class SVNCatalogRepository:
    def __init__(self, path):
        self._path = path
        xml = subprocess.check_output(["svn", "info", "--xml", path])
        root = ET.fromstring(xml)
        
        if (root.find(".//repository/root") == None):
            raise RuntimeError("Not an SVN repository:" + path)
    
    def hasPathChanged(self, path, oldRevision):
        return self.scmRevisionForPath(path) != oldRevision
        
    def scmRevisionForPath(self, path):
        xml = subprocess.check_output(["svn", "info", "--xml", path])
        root = ET.fromstring(xml)
        commit = root.find(".//entry/commit")
        return commit.get('revision', 0)
        
    def update(self):
        subprocess.call(["svn", "update"])
        