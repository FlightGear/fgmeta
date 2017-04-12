#!/usr/bin/python

import unittest
import sgprops
import os
import catalog
import lxml.etree as ET

class UpdateCatalogTests(unittest.TestCase):
    def test_scan_set(self):
        info = catalog.scan_set_file("testData/Aircraft/f16", "f16a-set.xml", ["testData/OtherDir"])
        self.assertEqual(info['id'], 'f16a')
        self.assertEqual(info['name'], 'F16-A')
        self.assertEqual(info['primary-set'], True)
        self.assertEqual(info['variant-of'], None)
        self.assertEqual(info['author'], 'Wilbur Wright')
        self.assertEqual(info['rating_FDM'], 3)
        self.assertEqual(info['rating_model'], 5)
        self.assertEqual(len(info['tags']), 3)

    def test_scan_dir(self):
        (pkg, variants) = catalog.scan_aircraft_dir("testData/Aircraft/f16", ["testData/OtherDir"])

        self.assertEqual(pkg['id'], 'f16a')
        f16trainer = next(v for v in variants if v['id'] == 'f16-trainer')
        self.assertEqual(pkg['author'], 'Wilbur Wright')
        self.assertEqual(len(variants), 3)

        # test variant relatonship between
        self.assertEqual(pkg['variant-of'], None)
        self.assertEqual(pkg['primary-set'], True)

        self.assertEqual(f16trainer['variant-of'], None)
        self.assertEqual(f16trainer['primary-set'], False)

        f16b = next(v for v in variants if v['id'] == 'f16b')
        self.assertEqual(f16b['variant-of'], 'f16a')
        self.assertEqual(f16b['primary-set'], False)
        self.assertEqual(f16b['author'], 'James T Kirk')

        f16c = next(v for v in variants if v['id'] == 'f16c')
        self.assertEqual(f16c['variant-of'], 'f16a')
        self.assertEqual(f16c['primary-set'], False)

        self.assertEqual(f16c['author'], 'Wilbur Wright')


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
        catalog_root.write(cat_file, encoding='utf-8', xml_declaration=True, pretty_print=True)

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
        self.assertEqual(parsedPkgNode.getValue('author'), "Wilbur Wright");

        parsedVariants = parsedPkgNode.getChildren("variant")
        self.assertEqual(len(parsedVariants), 3)

        f16ANode = parsedPkgNode
        self.assertEqual(f16ANode.getValue('name'), 'F16-A');

        for index, pv in enumerate(parsedVariants):
            var = variants[index]
            self.assertEqual(pv.getValue('name'), var['name']);
            self.assertEqual(pv.getValue('description'), var['description']);

            if (var['id'] == 'f16-trainer'):
                self.assertEqual(pv.getValue('variant-of'), '_primary_')
                self.assertEqual(pv.getValue('author'), "Wilbur Wright");
            elif (var['id'] == 'f16b'):
                self.assertEqual(pv.getValue('variant-of'), 'f16a')
                self.assertEqual(pv.getValue('description'), 'The F16-B is an upgraded version of the F16A.')
                self.assertEqual(pv.getValue('author'), "James T Kirk");




if __name__ == '__main__':
    unittest.main()
