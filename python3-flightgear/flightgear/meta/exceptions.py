# -*- coding: utf-8 -*-

# exceptions.py --- Simple, general-purpose subclass of Exception
#
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

"""Simple, general-purpose Exception subclass."""


class FGPyException(Exception):
    def __init__(self, message=None, *, mayCapitalizeMsg=True):
        """Initialize an FGPyException instance.

        Except in cases where 'message' starts with a proper noun or
        something like that, its first character should be given in
        lower case. Automated treatments of this exception may print the
        message with its first character changed to upper case, unless
        'mayCapitalizeMsg' is False. In other words, if the case of the
        first character of 'message' must not be changed under any
        circumstances, set 'mayCapitalizeMsg' to False.

        """
        self.message = message
        self.mayCapitalizeMsg = mayCapitalizeMsg

    def __str__(self):
        return self.completeMessage()

    def __repr__(self):
        return "{}.{}({!r})".format(__name__, type(self).__name__, self.message)

    # Typically overridden by subclasses with a custom constructor
    def detail(self):
        return self.message

    def completeMessage(self):
        if self.message:
            return "{shortDesc}: {detail}".format(
                shortDesc=self.ExceptionShortDescription,
                detail=self.detail())
        else:
            return self.ExceptionShortDescription

    ExceptionShortDescription = "FlightGear Python generic exception"
