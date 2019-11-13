#!/usr/bin/python

import argparse
import datetime
from fnmatch import fnmatch, translate
import lxml.etree as ET
import os
from os.path import exists, join, relpath
from os import F_OK, access, walk
import re
import sgprops
import sys
import catalogTags
import zipfile

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

def make_aircraft_node(aircraftDirName, package, variants, downloadBase, mirrors):
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

    # primary URL is first
    download_url = downloadBase + aircraftDirName + '.zip'
    package_node.append( make_xml_leaf('url', download_url) )

    for m in mirrors:
        mu = m + aircraftDirName + '.zip'
        package_node.append( make_xml_leaf('url', mu) )


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


def make_aircraft_zip(repo_path, craft_name, zip_file, global_zip_excludes, verbose=True):
    """Create a zip archive of the given aircraft."""

    # Printout.
    if verbose:
        print("Zip file creation: %s.zip" % craft_name)

    # Go to the directory of crafts to catalog.
    savedir = os.getcwd()
    os.chdir(repo_path)

    # Clear out the old file.
    if exists(zip_file):
        os.remove(zip_file)

    # Use the Python zipfile module to create the zip file.
    zip_handle = zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED)

    # Find a per-craft exclude list.
    craft_path = join(repo_path, craft_name)
    exclude_file = join(craft_path, 'zip-excludes.lst')
    if exists(exclude_file):
        if verbose:
            print("Found the craft specific exclusion list '%s'" % exclude_file)

    # Otherwise use the catalog default exclusion list.
    else:
        exclude_file = global_zip_excludes

    # Process the exclusion list and find all matching file names.
    blacklist = fetch_zip_exclude_list(craft_name, craft_path, exclude_file)

    # Walk over all craft files.
    print_format = "  %-30s '%s'"
    for root, dirs, files in walk(craft_path):
        # Loop over the files.
        for file in files:
            # The directory and relative and absolute paths.
            dir = relpath(root, start=repo_path)
            full_path = join(root, file)
            rel_path = relpath(full_path, start=repo_path)

            # Skip blacklist files or directories.
            skip = False
            if file == 'zip-excludes.lst':
                if verbose:
                    print(print_format % ("Skipping the file:", join(dir, 'zip-excludes.lst')))
                skip = True
            if dir in blacklist:
                if verbose:
                    print(print_format % ("Skipping the file:", join(dir, file)))
                skip = True
            for name in blacklist:
                if fnmatch(rel_path, name):
                    if verbose:
                        print(print_format % ("Skipping the file:", rel_path))
                    skip = True
                    break
            if skip:
                continue

            # Otherwise add the file.
            zip_handle.write(rel_path)

    # Clean up.
    os.chdir(savedir)
    zip_handle.close()


def fetch_zip_exclude_list(name, path, exclude_path):
    """Use Unix style path regular expression to find all files to exclude."""

    # Init.
    blacklist = []
    file = open(exclude_path)
    exclude_list = file.readlines()
    file.close()
    old_path = os.getcwd()
    os.chdir(path)

    # Process each exclusion path or regular expression, converting to Python RE objects.
    reobj_list = []
    for i in range(len(exclude_list)):
        reobj_list.append(re.compile(translate(exclude_list[i].strip())))

    # Recursively loop over all files, finding the ones to exclude.
    for root, dirs, files in walk(path):
        for file in files:
            full_path = join(root, file)
            rel_path = join(name, relpath(full_path, start=path))

            # Skip Unix shell-style wildcard matches
            for i in range(len(reobj_list)):
                if reobj_list[i].match(rel_path):
                    blacklist.append(rel_path)
                    break

    # Return to the original path.
    os.chdir(old_path)

    # Return the list.
    return blacklist


def parse_config_file(parser=None, file_name=None):
    """Test and parse the catalog configuration file."""

    # Check for the file.
    if not access(file_name, F_OK):
        print("CatalogError: The catalog configuration file '%s' cannot be found." % file_name)
        sys.exit(1)

    # Parse the XML and return the root node.
    config = ET.parse(file_name, parser)
    return config.getroot()


def parse_template_file(parser=None, file_name=None):
    """Test and parse the catalog configuration file."""

    # Check for the file.
    if not access(file_name, F_OK):
        print("CatalogError: The catalog template file '%s' cannot be found." % file_name)
        sys.exit(1)

    # Parse the XML and return the template node.
    template = ET.parse(file_name, parser)
    template_root = template.getroot()
    return template_root.find('template')
