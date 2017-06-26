# -*- coding: utf-8 -*-

# logging.py --- Simple logging infrastructure (mostly taken from FFGo)
# Copyright (C) 2015, 2017  Florent Rougon
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

import sys

from . import misc


class LogLevel(misc.OrderedEnum):
    debug, info, notice, warning, error, critical = range(6)

# List containing the above log levels as strings in increasing priority order
allLogLevels = [member.name for member in LogLevel]
allLogLevels.sort(key=lambda n: LogLevel[n].value)


def _logFuncFactory(level):
    def logFunc(self, *args, **kwargs):
        self.log(LogLevel[level], True, *args, **kwargs)

    def logFunc_noPrefix(self, *args, **kwargs):
        self.log(LogLevel[level], False, *args, **kwargs)

    return (logFunc, logFunc_noPrefix)


class Logger:
    def __init__(self, progname=None, logLevel=LogLevel.notice,
                 defaultOutputStream=sys.stdout, logFile=None):
        self.progname = progname
        self.logLevel = logLevel
        self.defaultOutputStream = defaultOutputStream
        self.logFile = logFile

    def setLogFile(self, *args, **kwargs):
        self.logFile = open(*args, **kwargs)

    def log(self, level, printLogLevel, *args, **kwargs):
        if printLogLevel and level >= LogLevel.warning and args:
            args = [level.name.upper() + ": " + args[0]] + list(args[1:])

        if level >= self.logLevel:
            if (self.progname is not None) and args:
                tArgs = [self.progname + ": " + args[0]] + list(args[1:])
            else:
                tArgs = args

            kwargs["file"] = self.defaultOutputStream
            print(*tArgs, **kwargs)

        if self.logFile is not None:
            kwargs["file"] = self.logFile
            print(*args, **kwargs)

    # Don't overload log() with too many tests or too much indirection for
    # little use
    def logToFile(self, *args, **kwargs):
        kwargs["file"] = self.logFile
        print(*args, **kwargs)

    # NP functions are “no prefix” variants which never prepend the log level
    # (otherwise, it is only prepended for warning and higher levels).
    debug, debugNP = _logFuncFactory("debug")
    info, infoNP = _logFuncFactory("info")
    notice, noticeNP = _logFuncFactory("notice")
    warning, warningNP = _logFuncFactory("warning")
    error, errorNP = _logFuncFactory("error")
    critical, criticalNP = _logFuncFactory("critical")


class DummyLogger(Logger):
    def setLogFile(self, *args, **kwargs):
        pass

    def log(self, *args, **kwargs):
        pass

    def logToFile(self, *args, **kwargs):
        pass
