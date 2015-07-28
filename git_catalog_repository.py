# git diff --quiet e5f841bc84d31fee339191a59b8746cb4eb8074c -- ./Aircraft/

import subprocess
import os, sgprops

class GITCatalogRepository:
    def __init__(self, node, singleAircraft = False):
        self._path = node.getValue("path")

        if not os.path.exists(os.path.join(self._path , ".git")):
            raise RuntimeError("not a Git directory:" + self._path )

        self._usesSubmodules = node.getValue("uses-submodules", False)
        self._singleAircraft = singleAircraft

        self._currentRevision = subprocess.check_output(["git", "rev-parse", "HEAD"],
            cwd = self._path)

        self._aircraftPath = None
        if node.hasChild("scan-suffix"):
            self._aircraftPath = os.path.join(path, node.getValue("scan-suffix"))

    @property
    def path(self):
        return self._path

    @property
    def aircraftPath(self):
        return self._aircraftPath

    def hasPathChanged(self, path, oldRev):
        diffArgs = ["git", "diff", "--quiet", oldRev, "--"]
        if not (self._usesSubmodules and self._singleAircraft):
            diffArgs.append(path)

        return subprocess.call(diffArgs, cwd = self._path)

    def update(self):
        subprocess.call(["git", "pull"])
        self._currentRevision = subprocess.check_output(["git", "rev-parse", "HEAD"],
                cwd = self._path)

        if self._usesSubmodules:
            subprocess.call(["git", "submodule", "update"], cwd = self._path)

    def scmRevisionForPath(self, path):
        if self._usesSubmodules:
            return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd = self._path)

        return self._currentRevision
