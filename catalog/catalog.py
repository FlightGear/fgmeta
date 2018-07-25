#!/usr/bin/python

import argparse
import datetime
import xml.etree.cElementTree as ET
import os
import re
import sgprops
import sys
import catalogTags

CATALOG_VERSION = 4
quiet = False
verbose = False

def warning(msg):
    if not quiet:
        print(msg)

def log(msg):
    if verbose:
        print(msg)

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

    # allow -set.xml files to specifcially exclude themselves from
    # the creation process, by setting <exclude-from-catalog>true</>
    if (sim_node.getValue("exclude-from-catalog", False) == True):
        return None

    variant = {}
    name = sim_node.getValue("description", None)
    if (name == None or len(name) == 0):
        warning("Set file " + set_file + " is missing a <description>, skipping")
        return None

    variant['name'] =  name
    variant['status'] = sim_node.getValue("status", None)

    if sim_node.hasChild('authors'):
        # aircraft has structured authors data, handle that
        variant['authors'] = sim_node.getChild('authors')
    
    # can have legacy author tag alongside new strucutred data for
    # backwards FG compatability
    if sim_node.hasChild('author'):
        variant['author'] = sim_node.getValue("author", None)

    if sim_node.hasChild('maintainers'):
        variant['maintainers'] = sim_node.getChild('maintainers')

    if sim_node.hasChild('urls'):
        variant['urls'] = sim_node.getChild('urls')

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
        variant['rating'] = sim_node.getChild("rating")

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
            warning("Bad preview path, skipping:" + fullPath)
            continue
        result.append({'type':previewType, 'path':previewPath})

    return result

def extract_tags(tags_node, set_path):
    result = []
    for node in tags_node.getChildren("tag"):
        tag = node.value
        # check tag is in the allowed list
        if not catalogTags.isValidTag(tag):
            warning("Unknown tag value:" + tag + " in " + set_path)
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

    # print setDicts
    if len(setDicts) == 0:
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

def append_author_nodes(node, info):
    if 'authors' in info:
        node.append(info['authors']._createXMLElement())
    if 'author' in info:
        # traditional single author string
        node.append( make_xml_leaf('author', info['author']) )

def make_aircraft_node(aircraftDirName, package, variants, downloadBase):
    #print "package:", package
    #print "variants:", variants
    package_node = ET.Element('package')
    package_node.append( make_xml_leaf('name', package['name']) )
    package_node.append( make_xml_leaf('status', package['status']) )

    append_author_nodes(package_node, package)

    if 'description' in package:
        package_node.append( make_xml_leaf('description', package['description']) )

    if 'minimum-fg-version' in package:
        package_node.append( make_xml_leaf('minimum-fg-version', package['minimum-fg-version']) )

    if 'rating' in package:
        package_node.append(package['rating']._createXMLElement())
       
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
        append_author_nodes(variant_node, variant)

    package_node.append( make_xml_leaf('dir', aircraftDirName) )

    download_url = downloadBase + aircraftDirName + '.zip'
    package_node.append( make_xml_leaf('url', download_url) )

    if 'thumbnail' in package:
        thumbnail_url = downloadBase + 'thumbnails/' + aircraftDirName + '_' + package['thumbnail']
        package_node.append( make_xml_leaf('thumbnail', thumbnail_url) )
        package_node.append( make_xml_leaf('thumbnail-path', package['thumbnail']))

    append_preview_nodes(package_node, package, downloadBase, aircraftDirName)
    append_tag_nodes(package_node, package)

    if 'maintainers' in package:
        package_node.append(package['maintainers']._createXMLElement())

    if 'urls' in package:
        package_node.append(package['urls']._createXMLElement())

    return package_node
