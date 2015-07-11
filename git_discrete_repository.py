# git diff --quiet e5f841bc84d31fee339191a59b8746cb4eb8074c -- ./Aircraft/
 
import subprocess
import os
import sgprops

import git_catalog_repository

class GitDiscreteSCM:
    def __init__(self, node):
        
        configNode = node.parent
        
        self._repos = {}
        
        # iterate over aicraft paths finding repositories
        for g in config.getChildren("aircraft-dir"):     
            repo = GITCatalogRepository(g, useSubmodules = False, 
                singleAircraft = True)
        

    def hasPathChanged(self, path, oldRev):
        
        return self._repos[path].hasPathChanged(path, oldRev)

    def update(self):
        for r in self._repos:
            r.update()

    def scmRevisionForPath(self, path):
        return self._repos[path].scmRevisionForPath(path)
        

 