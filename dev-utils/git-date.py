#! /usr/bin/env python3
# -*- coding: utf-8 -*-

# git-date.py --- Find Git commits around some date in one or more repositories.
# Copyright (c) 2021, Florent Rougon
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of the FlightGear project.

# The idea and some Git-fu of this script are from Edward d'Auvergne:
# <https://sourceforge.net/p/flightgear/mailman/message/37004175/>.

import argparse
import locale
import os
import re
import subprocess
import sys
from collections import namedtuple, OrderedDict

PROGNAME = os.path.basename(sys.argv[0])
PROGVERSION = "0.2"
COPYRIGHT = "Copyright (c) 2021, Florent Rougon"
LICENSE_SUMMARY = """\
This program is free software. It comes without any warranty, to
the extent permitted by applicable law. See the top of {progname}
for more details on the licensing conditions.""".format(progname=PROGNAME)

# Very simple Repository class
Repository = namedtuple('Repository', ['label', 'path'])


class CommitFinder:

    def __init__(self, branch, date):
        self.branch = branch
        self.date = date

    def findCommit(self, repo_path):
        """Return a commit ID that belongs to 'repo_path'."""
        args = ["git", "rev-list", "--max-count=1",
                "--before={}".format(self.date), self.branch]
        p = subprocess.run(args, cwd=repo_path, capture_output=True,
                           check=True, encoding="utf-8")
        return p.stdout.strip()

    def action(self, repositories):
        """Act on one or more repositories.

        'repositories' should be an OrderedDict whose keys are
        repository labels and values Repository objects.

        """
        for label, repo in repositories.items():
            commitId = self.findCommit(repo.path)
            if params.let_me_breathe: self.print("-" * 78)
            if not params.checkout: # the output would be redundant
                if params.only_label:
                    # Useful with --show-commits
                    #             --show-commits-option='--no-patch'
                    #             --show-commits-option='--format=oneline'
                    self.print("{}: ".format(label), end='')
                else:
                    self.print("{}: {}".format(label, commitId))
                if params.let_me_breathe: self.print()

            if params.show_commits:
                args = ["git", "-c", "pager.show=false", "show"] + \
                       params.show_commits_options + [commitId]
                subprocess.run(args, cwd=repo.path, check=True)

            if params.checkout:
                args = ["git", "checkout", commitId]
                self.print("{}: checking out commit {}...".format(label,
                                                                  commitId))
                subprocess.run(args, cwd=repo.path, check=True)

            if params.let_me_breathe: self.print()

    def print(self, *args, **kwargs):
        """Wrapper for print() that defaults to flushing the output stream.

        This is particularly useful when stdout is fully buffered (e.g.,
        when piping the output of the script through a pager). Without
        this 'flush=True' setting, output from Git commands would bypass
        the high-level buffering layer in sys.stdout and could come out
        before the output of some *later* non-flushed print()
        statements.
        """
        print(*args, flush=True, **kwargs)


def parseConfigFile(cfgFile, configFileOptSpecified, recognizedParams):
    namespace = argparse.Namespace()
    l = {}
    if configFileOptSpecified or os.path.exists(cfgFile):
        # Read the configuration file (i.e., execute it)
        with open(cfgFile, "r") as f:
            exec(f.read(), {"OrderedDict": OrderedDict}, l)

    for p in recognizedParams:
        if p in l:
            setattr(namespace, p, l[p])

    return namespace


def processCommandLineAndConfigFile():
    defaultCfgFile = os.path.join(os.getenv('HOME'),
                                  ".config", PROGNAME, "config.py")
    parser = argparse.ArgumentParser(
usage="""\
%(prog)s [OPTION ...] DATE [REPOSITORY...]
Find Git commits before DATE in one or more repositories.""",
        description="""\
Print information about, and possibly check out the most recent commit
before DATE in each of the specified repositories. By default, commits
are searched for in the 'next' branch, however this can be changed using
the --branch option or the 'branch' variable in the configuration file.
DATE can be in any date format accepted by Git (see the examples below).

If option --repo-args-are-just-paths has been given, each REPOSITORY
argument is literally treated as a path to a repository. Otherwise, each
REPOSITORY argument that has the form LABEL=PATH defines a repository
rooted at PATH with associated LABEL (using this special syntax is not
mandatory, but allows {progname} to refer to your repositories using the
provided labels, which is more user-friendly in general).

Examples (the backslashes just introduce continuation lines):

# One output line per repository (terse)
{progname} "2021-02-28 23:12:00" SG=/path/to/SG \\
            FG=/path/to/FG FGData=/path/to/FGData

# Ditto without providing the repository labels
{progname} "2021-02-28 23:12:00" /path/to/SG \\
            /path/to/FG /path/to/FGData

# Run 'git show' with the specified options for each commit found.
{progname} --let-me-breathe --show-commits \\
            --show-commits-option='--no-patch' \\
            --show-commits-option='--format=medium' \\
            '2021-02-28 23:12:00' SG=/path/to/SG \\
            FG=/path/to/FG FGData=/path/to/FGData

# Run 'git checkout' for each commit found.
{progname} --checkout --let-me-breathe "2021-01-01" SG=/path/to/SG \\
            FG=/path/to/FG FGData=/path/to/FGData

# For each repository, print the label, commit ID and one-line description.
{progname} --only-label --show-commits \\
            --show-commits-option='--no-patch' \\
            --show-commits-option='--format=oneline' \\
            "2021-02-28" SG=/path/to/SG \\
            FG=/path/to/FG FGData=/path/to/FGData

Note: --show-commits et al. may be used in conjunction with --checkout
      if so desired.

If $HOME/.config/{progname}/config.py exists or if the --config-file option
has been given, a configuration file is read. This file is executed by
the Python interpreter and must therefore adhere to Python 3 syntax.
Here is a sample configuration file:

------------------------------------------------------------------------------
branch = 'release/2020.3'
# checkout = True
# show_commits = True
# show_commits_options = ['--no-patch', '--format=medium']
# let_me_breathe = True
# only_label = True
# repo_args_are_just_paths = True

# collections.OrderedDict is available for use here:
repositories = OrderedDict(
    SimGear    = "/path/to/simgear",
    FlightGear = "/path/to/flightgear",
    FGData     = "/path/to/fgdata")

# Same list of repositories but without user-defined labels:
# repositories = [
#     "/path/to/simgear",
#     "/path/to/flightgear",
#     "/path/to/fgdata"]
------------------------------------------------------------------------------

Command-line options take precedence over their counterparts found in
the configuration file. On the other hand, REPOSITORY arguments *extend*
the list of repositories that may be defined in the configuration file
using the 'repositories' variable.""".format(progname=PROGNAME),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        # I want --help but not -h (it might be useful for something else)
        add_help=False)

    parser.add_argument('--repo-args-are-just-paths',
                        action='store_true', help="""\
      don't try to recognize and special-case LABEL=PATH syntax for
      repository arguments; treat them literally as paths and simply assign
      labels 'Repo 1', 'Repo 2', etc., to the specified repositories""")
    parser.add_argument('-b', '--branch', default="next", help="""\
      search history of BRANCH (default: %(default)s)""")
    parser.add_argument('-c', '--checkout', action='store_true', help="""\
      run 'git checkout' for the commit that was found in each repository""")
    # This option is actually handled by configFileOptParser because we want to
    # treat it before all other options.
    parser.add_argument('--config-file', metavar="FILE", default=defaultCfgFile,
                        help="""\
      load configuration from FILE  (default: %(default)s""")
    parser.add_argument('-s', '--show-commits', action='store_true', help="""\
      run 'git show' for the commit that was found in each repository""")
    parser.add_argument('-S', '--show-commits-option', action='append',
                        dest='show_commits_options', help="""\
      option passed to 'git show' when --show-commits is used (may be
      specified multiple times, as in: --show-commits-option='--no-patch'
      --show-commits-option='--format=medium')""")
    parser.add_argument('--let-me-breathe', action='store_true', help="""\
      add blank lines and other separators to make the output hopefully more
      readable when Git prints a lot of things""")
    parser.add_argument('--only-label', action='store_true', help="""\
      don't print the commit ID after the repository label (this is useful
      when the Git output coming next already contains the commit ID)""")
    parser.add_argument('date', metavar="DATE", help="""\
      find commits before this date""")
    parser.add_argument('cmdRepos', metavar="REPOSITORY", nargs='*',
                        help="""\
      path to a repository to act on (as many arguments of this type as desired
      can be given)""")
    parser.add_argument('--help', action="help",
                        help="display this message and exit")
    parser.add_argument('--version', action='version',
                        version="{name} version {version}\n{copyright}\n\n"
                                "{license}".format(
                                    name=PROGNAME, version=PROGVERSION,
                                    copyright=COPYRIGHT,
                                    license=LICENSE_SUMMARY))

    # Find which config file to read and note whether the --config-file option
    # was given.
    configFileOptParser = argparse.ArgumentParser(add_help=False)
    configFileOptParser.add_argument('--config-file')
    ns, remaining = configFileOptParser.parse_known_args()
    if ns.config_file is not None:
        configFileOptSpecified = True
    else:
        configFileOptSpecified = False
        ns.config_file = defaultCfgFile

    recognizedParams = ("repo_args_are_just_paths", "branch", "checkout",
                        "show_commits", "show_commits_options",
                        "let_me_breathe", "only_label", "repositories")
    # Read the config file into 'params' (an argparse.Namespace object)
    params = parseConfigFile(ns.config_file, configFileOptSpecified,
                             recognizedParams)

    # Process the rest of the command-line
    parser.parse_args(namespace=params)

    if "repositories" not in params:
        sys.exit(f"{PROGNAME}: no repository was specified, neither in the "
                 "configuration file\nnor on the command line; exiting.")

    # Prepare the final list of repositories based on the config file and the
    # command line arguments.
    params.repositories = initListOfRepositories(
        params.repositories, params.cmdRepos, params.repo_args_are_just_paths)
    return params


# Returns an OrderedDict whose keys are repository labels and values Repository
# objects.
def initListOfRepositories(reposFromCfgFile, reposFromCmdLineArgs,
                           repoArgsAreJustPaths):
    res = OrderedDict()
    reposLeftToAdd = []

    if isinstance(reposFromCfgFile, OrderedDict):
        for label, path in reposFromCfgFile.items():
            res[label] = Repository(label, path)
    elif isinstance(reposFromCfgFile, list):
        reposLeftToAdd.extend(reposFromCfgFile)
    else:
        sys.exit(f"{PROGNAME}: in the configuration file, 'repositories' must "
                 "be either an OrderedDict or a list.")

    repoNum = len(res)
    for elt in reposLeftToAdd + reposFromCmdLineArgs:
        repoNum += 1
        mo = re.match(r"^(?P<label>\w+)=(?P<path>.*)", elt)
        if mo is None or repoArgsAreJustPaths:
            label = "Repo {}".format(repoNum)
            path = elt
        else:
            label, path = mo.group("label", "path")
        res[label] = Repository(label, path)

    return res


def main():
    global params

    locale.setlocale(locale.LC_ALL, '')
    # Require Python 3.6 or later because we rely on the retained order for
    # keyword arguments passed to the OrderedDict constructor.
    if sys.hexversion < 0x030600F0:
        sys.exit(f"{PROGNAME}: exiting because Python >= 3.6 is required.")

    params = processCommandLineAndConfigFile()
    commitFinder = CommitFinder(params.branch, params.date)
    commitFinder.action(params.repositories)
    sys.exit(0)


if __name__ == "__main__": main()
