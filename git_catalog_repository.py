# git diff --quiet e5f841bc84d31fee339191a59b8746cb4eb8074c -- ./Aircraft/
 
import subprocess
import os

class GITCatalogRepository:
    def __init__(self, path, usesSubmodules = False, singleAircraft = False):
        self._path = path
        
        if not os.path.exists(os.path.join(path, ".git")):
            raise RuntimeError("not a Git directory:" + path)
        
        self._usesSubmodules = usesSubmodules
        self._singleAircraft = singleAircraft
        
        self._currentRevision = subprocess.catch_output(["git", "rev-parse", "HEAD"],
            cwd = self._path)

    def hasPathChanged(self, path, oldRev):
        diffArgs = ["git", "diff", "--quiet", oldRev, "--"]
        if not (self._usesSubmodules and self._singleAircraft):
            diffArgs.append(path)
            
        return subprocess.call(diffArgs, cwd = self._path)

    def update(self):
        subprocess.call(["git", "pull"])
        self._currentRevision = subprocess.catch_output(["git", "rev-parse", "HEAD"],
                cwd = self._path)
        
        if self._usesSubmodules:
            subprocess.call(["git", "submodule", "update"], cwd = self._path)    

    def scmRevisionForPath(self, path):
        if self._usesSubmodules:
            return subprocess.catch_output(["git", "rev-parse", "HEAD"], cwd = self._path)
            
        return self._currentRevision

 