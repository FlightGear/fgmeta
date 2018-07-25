#!/usr/bin/python

import unittest
import sgprops
import os
import catalog
import xml.etree.cElementTree as ET

catalog.quiet = True

class UpdateCatalogTests(unittest.TestCase):
    def test_scan_set(self):
        info = catalog.scan_set_file("testData/Aircraft/f16", "f16a-set.xml", ["testData/OtherDir"])
        self.assertEqual(info['id'], 'f16a')
        self.assertEqual(info['name'], 'F16-A')
        self.assertEqual(info['primary-set'], True)
        self.assertEqual(info['variant-of'], None)
       # self.assertEqual(info['rating_FDM'], 3)
      #  self.assertEqual(info['rating_model'], 5)

        ratings = info['rating']
        self.assertEqual(ratings.getValue('FDM'), 3)
        self.assertEqual(ratings.getValue('model'), 5)

        self.assertEqual(len(info['tags']), 3)
        self.assertEqual(info['minimum-fg-version'], '2017.4')

        authors = info['authors']
        self.assertNotIn('author', info)
        self.assertEqual(len(authors.getChildren()), 2)

        self.assertEqual(authors.getValue('author[0]/name'), 'Wilbur Wright')
        self.assertEqual(authors.getValue('author[0]/nick'), 'wilburw')
        self.assertEqual(authors.getValue('author[0]/email'), 'ww@wright.com')
        self.assertEqual(authors.getValue('author[1]/name'), 'Orville Wright')


    def test_scan_dir(self):
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/f16", ["testData/OtherDir"])

        self.assertEqual(pkg['id'], 'f16a')
        f16trainer = next(v for v in variants if v['id'] == 'f16-trainer')
        self.assertEqual(len(variants), 3)
        self.assertEqual(pkg['minimum-fg-version'], '2017.4')

        # test variant relatonship between
        self.assertEqual(pkg['variant-of'], None)
        self.assertEqual(pkg['primary-set'], True)

        self.assertEqual(f16trainer['variant-of'], None)
        self.assertEqual(f16trainer['primary-set'], False)

        f16b = next(v for v in variants if v['id'] == 'f16b')
        self.assertEqual(f16b['variant-of'], 'f16a')
        self.assertEqual(f16b['primary-set'], False)

        authorsArray = f16b['authors']
        self.assertNotIn('author', f16b)

        self.assertEqual(authorsArray.getValue('author[0]/name'), 'James T Kirk')
        self.assertEqual(authorsArray.getValue('author[0]/nick'), 'starlover')

        f16c = next(v for v in variants if v['id'] == 'f16c')
        self.assertEqual(f16c['variant-of'], 'f16a')
        self.assertEqual(f16c['primary-set'], False)

        authors = f16c['authors']
        self.assertNotIn('author', f16c)
        self.assertEqual(len(authors.getChildren()), 2)

    # test some older constructs for compat
    def test_scan_dir_legacy(self):
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/c172", [])

        self.assertEqual(pkg['id'], 'c172')
        self.assertEqual(pkg['author'], 'Wilbur Wright')

    def test_extract_previews(self):
        info = catalog.scan_set_file("testData/Aircraft/f16", "f16a-set.xml", ["testData/OtherDir"])
        previews = info['previews']
        self.assertEqual(len(previews), 3)
        self.assertEqual(2, len([p for p in previews if p['type'] == 'exterior']))
        self.assertEqual(1, len([p for p in previews if p['type'] == 'panel']))
        self.assertEqual(1, len([p for p in previews if p['path'] == 'Previews/exterior-1.png']))

    def test_extract_tags(self):
        info = catalog.scan_set_file("testData/Aircraft/f16", "f16a-set.xml", ["testData/OtherDir"])
        tags = info['tags']

    def test_node_creation(self):
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/f16", ["testData/OtherDir"])

        catalog_node = ET.Element('PropertyList')
        catalog_root = ET.ElementTree(catalog_node)

        pkgNode = catalog.make_aircraft_node('f16', pkg, variants, "http://foo.com/testOutput/")
        catalog_node.append(pkgNode)

        # write out so we can parse using sgprops
        # yes we are round-tripping via the disk, if you can improve
        # then feel free..
        if not os.path.isdir("testOutput"):
            os.mkdir("testOutput")

        cat_file = os.path.join("testOutput", 'catalog_fragment.xml')
        catalog_root.write(cat_file, encoding='utf-8', xml_declaration=True)

        parsed = sgprops.readProps(cat_file)
        parsedPkgNode = parsed.getChild("package")

        self.assertEqual(parsedPkgNode.name, "package");

        self.assertEqual(parsedPkgNode.getValue('id'), pkg['id']);
        self.assertEqual(parsedPkgNode.getValue('dir'), 'f16');
        self.assertEqual(parsedPkgNode.getValue('url'), 'http://foo.com/testOutput/f16.zip');
        self.assertEqual(parsedPkgNode.getValue('thumbnail'), 'http://foo.com/testOutput/thumbnails/f16_thumbnail.jpg');
        self.assertEqual(parsedPkgNode.getValue('thumbnail-path'), 'thumbnail.jpg');

        self.assertEqual(parsedPkgNode.getValue('name'), pkg['name']);
        self.assertEqual(parsedPkgNode.getValue('description'), pkg['description']);

        self.assertEqual(parsedPkgNode.getValue('minimum-fg-version'), "2017.4");

        parsedVariants = parsedPkgNode.getChildren("variant")
        self.assertEqual(len(parsedVariants), 3)

        # verify rating copying
        self.assertEqual(parsedPkgNode.getValue('rating/FDM'), 3)
        self.assertEqual(parsedPkgNode.getValue('rating/cockpit'), 2)
        self.assertEqual(parsedPkgNode.getValue('rating/model'), 5)


# author data verification
        self.assertFalse(parsedPkgNode.hasChild('author'));
        parsedAuthors = parsedPkgNode.getChild("authors").getChildren('author')

        self.assertEqual(len(parsedAuthors), 2)
        author1 = parsedAuthors[0]
        self.assertEqual(author1.getValue("name"), "Wilbur Wright")
        self.assertEqual(author1.getValue("nick"), "wilburw")
        self.assertEqual(author1.getValue("email"), "ww@wright.com")

        author2 = parsedAuthors[1]
        self.assertEqual(author2.getValue("name"), "Orville Wright")

        f16ANode = parsedPkgNode
        self.assertEqual(f16ANode.getValue('name'), 'F16-A');

        for index, pv in enumerate(parsedVariants):
            var = variants[index]
            self.assertEqual(pv.getValue('name'), var['name']);
            self.assertEqual(pv.getValue('description'), var['description']);

            if (var['id'] == 'f16-trainer'):
                self.assertEqual(pv.getValue('variant-of'), '_primary_')
            #    self.assertEqual(pv.getValue('author'), "Wilbur Wright");
            elif (var['id'] == 'f16b'):
                self.assertEqual(pv.getValue('variant-of'), 'f16a')
                self.assertEqual(pv.getValue('description'), 'The F16-B is an upgraded version of the F16A.')

                # variant author verification
                parsedAuthors = pv.getChild("authors").getChildren('author')
                author1 = parsedAuthors[0]
                self.assertEqual(author1.getValue("name"), "James T Kirk")
                self.assertEqual(author1.getValue("nick"), "starlover")
                self.assertEqual(author1.getValue("email"), "shatner@enterprise.com")
                self.assertEqual(author1.getValue("description"), "Everything")

    def test_node_creation2(self):
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/dc3", ["testData/OtherDir"])

        catalog_node = ET.Element('PropertyList')
        catalog_root = ET.ElementTree(catalog_node)

        pkgNode = catalog.make_aircraft_node('dc3', pkg, variants, "http://foo.com/testOutput/")
        catalog_node.append(pkgNode)

        if not os.path.isdir("testOutput"):
            os.mkdir("testOutput")

        cat_file = os.path.join("testOutput", 'catalog_fragment2.xml')
        catalog_root.write(cat_file, encoding='utf-8', xml_declaration=True)

        parsed = sgprops.readProps(cat_file)
        parsedPkgNode = parsed.getChild("package")

        self.assertEqual(parsedPkgNode.name, "package");

        self.assertEqual(parsedPkgNode.getValue('id'), pkg['id']);
        self.assertEqual(parsedPkgNode.getValue('dir'), 'dc3');
        self.assertEqual(parsedPkgNode.getValue('url'), 'http://foo.com/testOutput/dc3.zip');
      
        self.assertEqual(parsedPkgNode.getValue('author'), 'Donald Douglas');

        parsedAuthors = parsedPkgNode.getChild("authors").getChildren('author')
        self.assertEqual(len(parsedAuthors), 1)
        author1 = parsedAuthors[0]
        self.assertEqual(author1.getValue("name"), "Donald Douglas")
        self.assertEqual(author1.getValue("nick"), "dd")
        self.assertEqual(author1.getValue("email"), "dd@douglas.com")

        urls = parsedPkgNode.getChild('urls')
        self.assertEqual(urls.getValue('home-page'), 'http://www.douglas.com')

    def test_minimalAircraft(self):
        # test an aircraft with a deliberately spartan -set.xml file with
        # most interesting data missing
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/c150", ["testData/OtherDir"])

        catalog_node = ET.Element('PropertyList')
        catalog_root = ET.ElementTree(catalog_node)

        pkgNode = catalog.make_aircraft_node('c150', pkg, variants, "http://foo.com/testOutput/")
        catalog_node.append(pkgNode)

        if not os.path.isdir("testOutput2"):
            os.mkdir("testOutput2")

        cat_file = os.path.join("testOutput2", 'catalog_fragment.xml')
        catalog_root.write(cat_file, encoding='utf-8', xml_declaration=True)

        parsed = sgprops.readProps(cat_file)
        parsedPkgNode = parsed.getChild("package")

        self.assertEqual(parsedPkgNode.getValue('id'), pkg['id'])
        self.assertEqual(parsedPkgNode.getValue('dir'), 'c150')
        self.assertEqual(parsedPkgNode.getValue('url'), 'http://foo.com/testOutput/c150.zip')
        self.assertFalse(parsedPkgNode.hasChild('thumbnail'))
        self.assertFalse(parsedPkgNode.hasChild('thumbnail-path'));

        self.assertEqual(parsedPkgNode.getValue('name'), pkg['name']);
        self.assertFalse(parsedPkgNode.hasChild('description'));
        self.assertFalse(parsedPkgNode.hasChild('author'));
        self.assertFalse(parsedPkgNode.hasChild('minimum-fg-version'));
        self.assertFalse(parsedPkgNode.hasChild('variant'));

if __name__ == '__main__':
    unittest.main()
