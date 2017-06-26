# -*- coding: utf-8 -*-

# misc.py --- Miscellaneous classes and/or functions
# Copyright (C) 2015-2017  Florent Rougon
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

import enum

# Based on an example from the 'enum' documentation
class OrderedEnum(enum.Enum):
    """Base class for enumerations whose members can be ordered.

    Contrary to enum.IntEnum, this class maintains normal enum.Enum
    invariants, such as members not being comparable to members of other
    enumerations (nor of any other class, actually).

    """
    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.value >= other.value
        return NotImplemented

    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.value > other.value
        return NotImplemented

    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.value <= other.value
        return NotImplemented

    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.value < other.value
        return NotImplemented

    def __eq__(self, other):
        if self.__class__ is other.__class__:
            return self.value == other.value
        return NotImplemented

    def __ne__(self, other):
        if self.__class__ is other.__class__:
            return self.value != other.value
        return NotImplemented


# Taken from <http://effbot.org/zone/element-lib.htm#prettyprint> and modified
# by Florent Rougon
def indentXmlTree(elem, level=0, basicOffset=2, lastChild=False):
    def indentation(level):
        return "\n" + level*basicOffset*" "

    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = indentation(level+1)

        for e in elem[:-1]:
            indentXmlTree(e, level+1, basicOffset, False)
        if len(elem):
            indentXmlTree(elem[-1], level+1, basicOffset, True)

    if level and (not elem.tail or not elem.tail.strip()):
        if lastChild:
            elem.tail = indentation(level-1)
        else:
            elem.tail = indentation(level)
