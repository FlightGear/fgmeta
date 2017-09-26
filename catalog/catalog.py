#!/usr/bin/python

import argparse
import datetime
import lxml.etree as ET
import os
import re
import sgprops
import sys
import catalogTags

CATALOG_VERSION = 4

# xml node (robust) get text helper
def get_xml_text(e):
    if e != None and e.text != None:
        return e.text
    else:
        return ''

# return all available aircraft information from the set file as a
# dict
def scan_set_file(aircraft_dir, set_file, includes):
    base_file = os.path.basename(set_file)
    base_id = base_file[:-8]
    set_path = os.path.join(aircraft_dir, set_file)

    includes.append(aircraft_dir)
    root_node = sgprops.readProps(set_path, includePaths = includes)

    if not root_node.hasChild("sim"):
        return None

    sim_node = root_node.getChild("sim")
    if sim_node == None:
        return None

    variant = {}
    variant['name'] = sim_node.getValue("description", None)
    variant['status'] = sim_node.getValue("status", None)

    if sim_node.hasChild('author'):
        variant['author'] = sim_node.getValue("author", None)

    if sim_node.hasChild('long-description'):
        variant['description'] = sim_node.getValue("long-description", None)
    variant['id'] = base_id

    # allow -set.xml files to declare themselves as primary.
    # we use this avoid needing a variant-of in every other -set.xml
    variant['primary-set'] = sim_node.getValue('primary-set', False)

    # extract and record previews for each variant
    if sim_node.hasChild('previews'):
        variant['previews'] = extract_previews(sim_node.getChild('previews'), aircraft_dir)

    if sim_node.hasChild('rating'):
        rating_node = sim_node.getChild("rating")
        variant['rating_FDM'] = rating_node.getValue("FDM", 0)
        variant['rating_systems'] = rating_node.getValue("systems", 0)
        variant['rating_cockpit'] = rating_node.getValue("cockpit", 0)
        variant['rating_model'] = rating_node.getValue("model", 0)

    if sim_node.hasChild('tags'):
        variant['tags'] = extract_tags(sim_node.getChild('tags'), set_file)

    if sim_node.hasChild('thumbnail'):
        variant['thumbnail'] = sim_node.getValue("thumbnail", None)

    variant['variant-of'] = sim_node.getValue("variant-of", None)

    if sim_node.hasChild('minimum-fg-version'):
        variant['minimum-fg-version'] = sim_node.getValue('minimum-fg-version', None)

    #print '    ', variant
    return variant

def extract_previews(previews_node, aircraft_dir):
    result = []
    for node in previews_node.getChildren("preview"):
        previewType = node.getValue("type", None)
        previewPath = node.getValue("path", None)

        # check path exists in base-name-dir
        fullPath = os.path.join(aircraft_dir, previewPath)
        if not os.path.isfile(fullPath):
            print "Bad preview path, skipping:" + fullPath
            continue
        result.append({'type':previewType, 'path':previewPath})

    return result

def extract_tags(tags_node, set_path):
    result = []
    for node in tags_node.getChildren("tag"):
        tag = node.value
        # check tag is in the allowed list
        if not catalogTags.isValidTag(tag):
            print "Unknown tag value:", tag, " in ", set_path
        result.append(tag)

    return result

# scan all the -set.xml files in an aircraft directory.  Returns a
# package dict and a list of variants.
def scan_aircraft_dir(aircraft_dir, includes):
    setDicts = []
    primaryAircraft = []
    package = None

    files = os.listdir(aircraft_dir)
    for file in sorted(files, key=lambda s: s.lower()):
        if file.endswith('-set.xml'):
            # print 'trying:', file
            try:
                d = scan_set_file(aircraft_dir, file, includes)
                if d == None:
                    continue
            except:
                print "Skipping set file since couldn't be parsed:", os.path.join(aircraft_dir, file), sys.exc_info()[0]
                continue

            setDicts.append(d)
            if d['primary-set']:
                # ensure explicit primary-set aircraft goes first
                primaryAircraft.insert(0, d)
            elif d['variant-of'] == None:
                primaryAircraft.append(d)

    print setDicts
    if len(setDicts) == 0:
        print 'returning none'
        return None, None

    # use the first one
    if len(primaryAircraft) == 0:
        print "Aircraft has no primary aircraft at all:", aircraft_dir
        primaryAircraft = [setDicts[0]]

    package = primaryAircraft[0]
    if not 'thumbnail' in package:
        if (os.path.exists(os.path.join(aircraft_dir, "thumbnail.jpg"))):
            package['thumbnail'] = "thumbnail.jpg"

    # variants is just all the set dicts except the first one
    variants = setDicts
    variants.remove(package)
    return (package, variants)

# create an xml node with text content
def make_xml_leaf(name, text):
    leaf = ET.Element(name)
    if text != None:
        if isinstance(text, (int, long)):
            leaf.text = str(text)
        else:
            leaf.text = text
    else:
        leaf.text = ''
    return leaf

def append_preview_nodes(node, variant, download_base, package_name):
    if not 'previews' in variant:
        return

    for preview in variant['previews']:
        preview_node = ET.Element('preview')
        preview_url = download_base + 'previews/' + package_name + '_' + preview['path']
        preview_node.append( make_xml_leaf('type', preview['type']) )
        preview_node.append( make_xml_leaf('url', preview_url) )
        preview_node.append( make_xml_leaf('path', preview['path']) )
        node.append(preview_node)

def append_tag_nodes(node, variant):
    if not 'tags' in variant:
        return

    for tag in variant['tags']:
        node.append(make_xml_leaf('tag', tag))

def make_aircraft_node(aircraftDirName, package, variants, downloadBase):
    #print "package:", package
    #print "variants:", variants
    package_node = ET.Element('package')
    package_node.append( make_xml_leaf('name', package['name']) )
    package_node.append( make_xml_leaf('status', package['status']) )

    if 'author' in package:
        package_node.append( make_xml_leaf('author', package['author']) )

    if 'description' in package:
        package_node.append( make_xml_leaf('description', package['description']) )

    if 'minimum-fg-version' in package:
        package_node.append( make_xml_leaf('minimum-fg-version', package['minimum-fg-version']) )

    if 'rating_FDM' in package or 'rating_systems' in package \
       or 'rating_cockpit' in package or 'rating_model' in package:
        rating_node = ET.Element('rating')
        package_node.append(rating_node)
        rating_node.append( make_xml_leaf('FDM',
                                          package['rating_FDM']) )
        rating_node.append( make_xml_leaf('systems',
                                          package['rating_systems']) )
        rating_node.append( make_xml_leaf('cockpit',
                                          package['rating_cockpit']) )
        rating_node.append( make_xml_leaf('model',
                                          package['rating_model']) )
    package_node.append( make_xml_leaf('id', package['id']) )
    for variant in variants:
        variant_node = ET.Element('variant')
        package_node.append(variant_node)
        variant_node.append( make_xml_leaf('id', variant['id']) )
        variant_node.append( make_xml_leaf('name', variant['name']) )
        if 'description' in variant:
            variant_node.append( make_xml_leaf('description', variant['description']) )

        if 'author' in variant:
            variant_node.append( make_xml_leaf('author', variant['author']) )

        if 'thumbnail' in variant:
            # note here we prefix with the package name, since the thumbnail path
            # is assumed to be unique within the package
            thumbUrl = downloadBase + "thumbnails/" + aircraftDirName + '_' + variant['thumbnail']
            variant_node.append(make_xml_leaf('thumbnail', thumbUrl))
            variant_node.append(make_xml_leaf('thumbnail-path', variant['thumbnail']))

        variantOf = variant['variant-of']
        if variantOf is None:
            variant_node.append(make_xml_leaf('variant-of', '_primary_'))
        else:
            variant_node.append(make_xml_leaf('variant-of', variantOf))

        append_preview_nodes(variant_node, variant, downloadBase, aircraftDirName)
        append_tag_nodes(variant_node, variant)

    package_node.append( make_xml_leaf('dir', aircraftDirName) )

    download_url = downloadBase + aircraftDirName + '.zip'
    package_node.append( make_xml_leaf('url', download_url) )

    if 'thumbnail' in package:
        thumbnail_url = downloadBase + 'thumbnails/' + aircraftDirName + '_' + package['thumbnail']
        package_node.append( make_xml_leaf('thumbnail', thumbnail_url) )
        package_node.append( make_xml_leaf('thumbnail-path', package['thumbnail']))

    append_preview_nodes(package_node, package, downloadBase, aircraftDirName)
    append_tag_nodes(package_node, package)

    return package_node
