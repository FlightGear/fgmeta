#! /usr/bin/env python3

import unittest

from flightgear.meta import sgprops


class SGProps(unittest.TestCase):

    def test_parse(self):
        parsed = sgprops.readProps("testData/props1.xml")

        self.assertEqual(parsed.getValue("value"), 42)
        self.assertEqual(type(parsed.getValue("value")), int)

        valNode = parsed.getChild("value")
        self.assertEqual(valNode.parent, parsed)
        self.assertEqual(valNode.name, "value")

        self.assertEqual(valNode.value, 42)
        self.assertEqual(type(valNode.value), int)

        with self.assertRaises(IndexError):
            missingNode = parsed.getChild("missing")

        things = parsed.getChildren("thing")
        self.assertEqual(len(things), 3)

        self.assertEqual(things[0], parsed.getChild("thing", 0));
        self.assertEqual(things[1], parsed.getChild("thing", 1));
        self.assertEqual(things[2], parsed.getChild("thing", 2));

        self.assertEqual(things[0].getValue("value"), "apple");
        self.assertEqual(things[1].getValue("value"), "lemon");
        self.assertEqual(things[2].getValue("value"), "pear");

    def test_create(self):
        pass


    def test_invalidIndex(self):
        with self.assertRaises(IndexError):
            parsed = sgprops.readProps("testData/bad-index.xml")

    def test_include(self):
        parsed = sgprops.readProps("testData/props2.xml")

        # test that value in main file over-rides the one in the include
        self.assertEqual(parsed.getValue("value"), 33)

        # but these come from the included file
        self.assertEqual(parsed.getValue("value[1]"), 43)
        self.assertEqual(parsed.getValue("value[2]"), 44)

        subNode = parsed.getChild("sub")
        widgets = subNode.getChildren("widget")
        self.assertEqual(len(widgets), 4)

        self.assertEqual(widgets[2].value, 44)
        self.assertEqual(widgets[3].value, 99)

if __name__ == '__main__':
    unittest.main()
