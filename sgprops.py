# SAX for parsing
from xml.sax import make_parser, handler, expatreader

# ElementTree for writing
import xml.etree.cElementTree as ET

import re, os

class Node(object):
    def __init__(self, name = '', index = 0, parent = None):
        self._parent = parent
        self._name = name
        self._value = None
        self._index = 0
        self._children = []

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, v):
        self._value = v

    @property
    def name(self):
        return self._name

    @property
    def index(self):
        return self._index

    @property
    def parent(self):
        return self._parent

    def getChild(self, n, i=None, create = False):

        if i is None:
            i = 0
            # parse name as foo[999] if necessary
            m = re.match(R"(\w+)\[(\d+)\]", n)
            if m is not None:
                n = m.group(1)
                i = int(m.group(2))

        for c in self._children:
            if (c.name == n) and (c.index == i):
                return c

        if create:
            c = Node(n, i, self)
            self._children.append(c)
            return c
        else:
            raise IndexError("no such child:" + str(n) + " index=" + str(i))

    def addChild(self, n):
        # adding an existing instance
        if isinstance(n, Node):
            n._parent = self
            n._index = self.firstUnusedIndex(n.name)
            self._children.append(n)
            return n

        i = self.firstUnusedIndex(n)
        # create it via getChild
        return self.getChild(n, i, create=True)

    def firstUnusedIndex(self, n):
        usedIndices = frozenset(c.index for c in self.getChildren(n))
        i = 0
        while i < 1000:
            if i not in usedIndices:
                 return i
            i += 1
        raise RuntimeException("too many children with name:" + n)

    def hasChild(self, nm):
        for c in self._children:
            if (c.name == nm):
                return True

        return False

    def getChildren(self, n = None):
        if n is None:
            return self._children

        return [c for c in self._children if c.name == n]

    def getNode(self, path, cr = False):
        axes = path.split('/')
        nd = self
        for ax in axes:
            nd = nd.getChild(ax, create = cr)

        return nd

    def getValue(self, path, default = None):
        try:
            nd = self.getNode(path)
            return nd.value
        except:
            return default

    def write(self, path):
        root = self._createXMLElement('PropertyList')
        t = ET.ElementTree(root)
        t.write(path, 'utf-8', xml_declaration = True)

    def _createXMLElement(self, nm = None):
        if nm is None:
            nm = self.name

        n = ET.Element(nm)

        # value and type specification
        try:
            if self._value is not None:
                if isinstance(self._value, basestring):
                    # don't call str() on strings, breaks the
                    # encoding
                    n.text = self._value
                else:
                    # use str() to turn non-string types into text
                    n.text = str(self._value)
                    if isinstance(self._value, int):
                        n.set('type', 'int')
                    elif isinstance(self._value, float):
                        n.set('type', 'double')
                    elif isinstance(self._value, bool):
                        n.set('type', "bool")
        except UnicodeEncodeError:
            print "Encoding error with", self._value, type(self._value)

        # index in parent
        if (self.index != 0):
            n.set('n', str(self.index))

        # children
        for c in self._children:
            n.append(c._createXMLElement())

        return n;


class PropsHandler(handler.ContentHandler):
    def __init__(self, root = None, path = None, dataDirPath = None):
        self._root = root
        self._path = path
        self._basePath = os.path.dirname(path)
        self._dataDirPath = dataDirPath
        self._locator = None

        if root is None:
            # make a nameless root node
            self._root = Node("", 0)
        self._current = self._root

    def setDocumentLocator(self, loc):
        self._locator = loc

    def startElement(self, name, attrs):
        self._content = None
        if (name == 'PropertyList'):
            return

        if 'n' in attrs.keys():
            index = int(attrs['n'])
            self._current = self._current.getChild(name, index, create=True)
        else:
            self._current = self._current.addChild(name)


        if 'include' in attrs.keys():
            self.handleInclude(attrs['include'])

        self._currentTy = None;
        if 'type' in attrs.keys():
            self._currentTy = attrs['type']

    def handleInclude(self, includePath):
        if includePath.startswith('/'):
            includePath = includePath[1:]

        p = os.path.join(self._basePath, includePath)
        if not os.path.exists(p):
            p = os.path.join(self._dataDirPath, includePath)
            if not os.path.exists(p):
                raise RuntimeError("include file not found", includePath, "at line", self._locator.getLineNumber())

        readProps(p, self._current, self._dataDirPath)

    def endElement(self, name):
        if (name == 'PropertyList'):
            return

        try:
            # convert and store value
            self._current.value = self._content
            if self._currentTy == "int":
                self._current.value = int(self._content)
            if self._currentTy == "bool":
                self._current.value = self.parsePropsBool(self._content)
            if self._currentTy == "double":
                self._current.value = float(self._content)
        except:
            print "Parse error for value:", self._content, "at line:", self._locator.getLineNumber(), "of:", self._path

        self._current = self._current.parent
        self._content = None

    def parsePropsBool(self, content):
        if content == "True" or content == "true":
            return True

        if content == "False" or content == "false":
            return False

        try:
            icontent = int(content)
            if icontent is not None:
                if icontent == 0:
                    return False
                else:
                    return True;
        except:
            return False

    def characters(self, content):
        if self._content is None:
            self._content = ''
        self._content += content

    def endDocument(self):
        pass

    @property
    def root(self):
        return self._root


def readProps(path, root = None, dataDirPath = None):
    parser = make_parser()
    locator = expatreader.ExpatLocator( parser )
    h = PropsHandler(root, path, dataDirPath)
    h.setDocumentLocator(locator)
    parser.setContentHandler(h)
    parser.parse(path)
    return h.root

def copy(src, dest):
    dest.value = src.value

    # recurse over children
    for c in src.getChildren() :
        dc = dest.getChild(c.name, i = c.index, create = True)
        copy(c, dc)
