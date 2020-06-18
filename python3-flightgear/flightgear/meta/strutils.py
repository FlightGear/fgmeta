# -*- coding: utf-8 -*-

# strutils.py --- Convenient string helpers
# Copyright (C) 2020  Florent Rougon
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

import re


_simplifyString_cre = re.compile(r"[ \t\n\r]+")

def simplify(s):
    """Strip and replace every internal run of whitespace with a single space.

    In this case, “whitespace” is defined as anything matching the
    regular expression '[ \t\n\r]+'.

    """
    return _simplifyString_cre.sub(" ", s.strip())
