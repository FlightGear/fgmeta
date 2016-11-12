#!/usr/bin/python

import argparse
import datetime
import hashlib                  # md5
import lxml.etree as ET
import os
import re
import shutil
import subprocess
import time

CATALOG_VERSION = 4

parser = argparse.ArgumentParser()
parser.add_argument("--update", help="Update/pull SCM source",
                    action="store_true")
parser.add_argument("--no-update",
                    help="Disable updating from SCM source",
                    action="store_true")
parser.add_argument("--clean", help="Force regeneration of all zip files",
                    action="store_true")
parser.add_argument("dir", help="Catalog directory")
args = parser.parse_args()

# xml node (robust) get text helper
def get_xml_text(e):
    if e != None and e.text != None:
        return e.text
    else:
        return ''

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

# return all available aircraft information from the set file as a
# dict
def scan_set_file(set_file):
    base_file = os.path.basename(set_file)
    base_id = base_file[:-8]
    #print '  scanning:', base_file
    parser = ET.XMLParser(remove_blank_text=True)
    set_xml = ET.parse(set_file, parser)
    set_node = set_xml.getroot()
    sim_node = set_node.find('sim')
    if sim_node == None:
        return None
    variant = {}
    variant['name'] = get_xml_text(sim_node.find('description'))
    variant['status'] = get_xml_text(sim_node.find('status'))
    variant['author'] = get_xml_text(sim_node.find('author'))
    variant['description'] = get_xml_text(sim_node.find('long-description'))
    variant['id'] = base_id
    rating_node = sim_node.find('rating')
    if rating_node != None:
        variant['rating_FDM'] = int(get_xml_text(rating_node.find('FDM')))
        variant['rating_systems'] = int(get_xml_text(rating_node.find('systems')))
        variant['rating_cockpit'] = int(get_xml_text(rating_node.find('cockpit')))
        variant['rating_model'] = int(get_xml_text(rating_node.find('model')))
    variant['variant-of'] = get_xml_text(sim_node.find('variant-of'))
    #print '    ', variant
    return variant

# scan all the -set.xml files in an aircraft directory.  Returns a
# package dict and a list of variants.
def scan_aircraft_dir(aircraft_dir):
    found_master = False
    package = None
    variants = []
    files = os.listdir(aircraft_dir)
    for file in sorted(files, key=lambda s: s.lower()):
        if file.endswith('-set.xml'):
            variant = scan_set_file(os.path.join(aircraft_dir, file))
            if variant == None:
                continue
            if package == None:
                # just in case no one claims to be master, the first
                # variant defaults to master, but we will overwrite
                # this if we find something better.
                package = variant
            if not found_master and variant['variant-of'] == '':
                found_master = True
                package = variant
            else:
                variants.append( {'id': variant['id'],
                                  'name': variant['name'] } )
    return (package, variants)

# use svn commands to report the last change date within dir
def last_change_date_svn(dir):
    command = [ 'svn', 'info', dir ]
    result = subprocess.check_output( command )
    match = re.search('Last Changed Date: (\d+)\-(\d+)\-(\d+)', result)
    if match:
        rev_str = match.group(1) + match.group(2) + match.group(3)
        return int(rev_str)

# find the most recent mtime within a directory subtree
def scan_dir_for_change_date_mtime(path):
    maxsec = 0
    names = os.listdir(path)
    for name in names:
        fullname = os.path.join(path, name)
        if name == '.' or name == '..':
            pass
        elif os.path.isdir( fullname ):
            mtime = scan_dir_for_change_date_mtime( fullname )
            if mtime > maxsec:
                maxsec = mtime
        else:
            mtime = os.path.getmtime( fullname )
            if mtime > maxsec:
                maxsec = mtime
    return maxsec

def make_aircraft_zip(repo_path, name, zip_file):
    print "Updating:", name + '.zip'
    savedir = os.getcwd()
    os.chdir(repo_path)
    if os.path.exists(zip_file):
        os.remove(zip_file)
    command = ['zip', '-rq', '-9']
    if os.path.exists(zip_excludes):
        command += ['-x@' + zip_excludes]
    else:
        print "warning: no zip-excludes.lst file provided", zip_excludes
    command += [zip_file, name]
    subprocess.call(command)
    os.chdir(savedir)

def get_md5sum(file):
    f = open(file, 'r')
    md5sum = hashlib.md5(f.read()).hexdigest()
    f.close()
    return md5sum

#def get_file_stats(file):
#    f = open(file, 'r')
#    md5 = hashlib.md5(f.read()).hexdigest()
#    file_size = os.path.getsize(file)
#    return (md5, file_size)

if not os.path.isdir(args.dir):
    print "A valid catalog directory must be provided"
    exit(0)

parser = ET.XMLParser(remove_blank_text=True)

config_file = os.path.join(args.dir, 'catalog.config.xml')
config = ET.parse(config_file, parser)
config_node = config.getroot()

template_file = os.path.join(args.dir, 'template.xml')
template = ET.parse(template_file, parser)
template_root = template.getroot()
template_node = template_root.find('template')

md5sum_file = os.path.join(args.dir, 'md5sum.xml')
if os.path.exists(md5sum_file):
    md5sum_tree = ET.parse(md5sum_file, parser)
    md5sum_root = md5sum_tree.getroot()
else:
    md5sum_root = ET.Element('PropertyList')
    md5sum_tree = ET.ElementTree(md5sum_root)

scm_list = config_node.findall('scm')
upload_node = config_node.find('upload')
download_base = get_xml_text(config_node.find('download-url'))
output_dir = get_xml_text(config_node.find('local-output'))
if output_dir == '':
    output_dir = os.path.join(args.dir, 'output')
if not os.path.isdir(output_dir):
    os.mkdir(output_dir)
thumbnail_dir = os.path.join(output_dir, 'thumbnails')
if not os.path.isdir(thumbnail_dir):
    os.mkdir(thumbnail_dir)
tmp = os.path.join(args.dir, 'zip-excludes.lst')
zip_excludes = os.path.realpath(tmp)

# freshen repositories
if args.no_update:
    print 'Skipping repository updates.'
else:
    cwd = os.getcwd()
    for scm in scm_list:
        repo_type = get_xml_text(scm.find('type'))
        repo_path = get_xml_text(scm.find('path'))
        if repo_type == 'svn':
            print 'SVN update:', repo_path
            subprocess.call(['svn', 'update', repo_path])
        elif repo_type == 'git':
            print 'GIT pull:', repo_path
            os.chdir(repo_path)
            subprocess.call(['git','pull'])
        elif repo_type == 'no-scm':
            print "No update of unmannaged files:", repo_path
        else:
            print "Unknown scm type:", scm, repo_path
    os.chdir(cwd)

# names of zip files we want (so we can identify/remove orphans)
valid_zips = []

# create the catalog tree
catalog_node = ET.Element('PropertyList')
catalog_root = ET.ElementTree(catalog_node)

# include the template configuration
for child in template_node:
    catalog_node.append(child)

# scan repositories for catalog information
for scm in scm_list:
    repo_type = get_xml_text(scm.find('type'))
    repo_path = get_xml_text(scm.find('path'))
    skip_nodes = scm.findall('skip')
    skip_list = []
    for s in skip_nodes:
        skip_list.append(get_xml_text(s))
    print 'skip list:', skip_list
    names = os.listdir(repo_path)
    for name in sorted(names, key=lambda s: s.lower()):
        if name in skip_list:
            print "skipping:", name
            continue
        aircraft_dir = os.path.join(repo_path, name)
        if os.path.isdir(aircraft_dir):
            print "%s:" % name,
            (package, variants) = scan_aircraft_dir(aircraft_dir)
            if package == None:
                print "skipping:", name, "(no -set.xml files)"
                continue
            #print "package:", package
            #print "variants:", variants
            package_node = ET.Element('package')
            package_node.append( make_xml_leaf('name', package['name']) )
            package_node.append( make_xml_leaf('status', package['status']) )
            package_node.append( make_xml_leaf('author', package['author']) )
            package_node.append( make_xml_leaf('description', package['description']) )
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

                if 'authors' in variant:
                    variant_node.append( make_xml_leaf('author', variant['author']) )

            package_node.append( make_xml_leaf('dir', name) )
            if not download_base.endswith('/'):
                download_base += '/'
            download_url = download_base + name + '.zip'
            thumbnail_url = download_base + 'thumbnails/' + name + '_thumbnail.jpg'
            package_node.append( make_xml_leaf('url', download_url) )
            package_node.append( make_xml_leaf('thumbnail', thumbnail_url) )

            # todo: url (download), thumbnail (download url)

            # get cached md5sum if it exists
            md5sum = get_xml_text(md5sum_root.find(str('aircraft_' + name)))

            # now do the packaging and rev number stuff
            dir_mtime = scan_dir_for_change_date_mtime(aircraft_dir)
            if repo_type == 'svn':
                rev = last_change_date_svn(aircraft_dir)
            else:
                d = datetime.datetime.utcfromtimestamp(dir_mtime)
                rev = d.strftime("%Y%m%d")
            package_node.append( make_xml_leaf('revision', rev) )
            #print "rev:", rev
            #print "dir mtime:", dir_mtime
            zipfile = os.path.join( output_dir, name + '.zip' )
            valid_zips.append(name + '.zip')
            if not os.path.exists(zipfile) \
               or dir_mtime > os.path.getmtime(zipfile) \
               or args.clean:
                # rebuild zip file
                print "updating:", zipfile
                make_aircraft_zip(repo_path, name, zipfile)
                md5sum = get_md5sum(zipfile)
            else:
                print "(no change)"
                if md5sum == "":
                    md5sum = get_md5sum(zipfile)
            filesize = os.path.getsize(zipfile)
            package_node.append( make_xml_leaf('md5', md5sum) )
            package_node.append( make_xml_leaf('file-size-bytes', filesize) )

            # handle md5sum cache
            node = md5sum_root.find('aircraft_' + name)
            if node != None:
                node.text = md5sum
            else:
                md5sum_root.append( make_xml_leaf('aircraft_' + name, md5sum) )

            # handle thumbnails
            thumbnail_src = os.path.join(aircraft_dir, 'thumbnail.jpg')
            thumbnail_dst = os.path.join(thumbnail_dir, name + '_thumbnail.jpg')
            if os.path.exists(thumbnail_src):
                shutil.copy2(thumbnail_src, thumbnail_dst)
            catalog_node.append(package_node)
            package_node.append( make_xml_leaf('thumbnail-path', 'thumbnail.jpg') )

# write out the master catalog file
cat_file = os.path.join(output_dir, 'catalog.xml')
catalog_root.write(cat_file, encoding='utf-8', xml_declaration=True, pretty_print=True)

# write out the md5sum cache file
print md5sum_file
md5sum_tree.write(md5sum_file, encoding='utf-8', xml_declaration=True, pretty_print=True)

# look for orphaned zip files
files = os.listdir(output_dir)
for file in files:
    if file.endswith('.zip')and not file in valid_zips:
        print "orphaned zip:", file
