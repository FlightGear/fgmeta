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
import sgprops
import sys
import catalogTags
import catalog

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

includes = []

# xml node (robust) get text helper
def get_xml_text(e):
    if e != None and e.text != None:
        return e.text
    else:
        return ''

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

def copy_previews_for_variant(variant, package_name, package_dir, previews_dir):
    if not 'previews' in variant:
        return

    for preview in variant['previews']:
        preview_src = os.path.join(package_dir, preview['path'])
        preview_dst = os.path.join(previews_dir, package_name + '_' + preview['path'])
        #print preview_src, preview_dst, preview['path']
        dir = os.path.dirname(preview_dst)
        if not os.path.isdir(dir):
            os.makedirs(dir)
        if os.path.exists(preview_src):
            shutil.copy2(preview_src, preview_dst)

def copy_previews_for_package(package, variants, package_name, package_dir, previews_dir):
    copy_previews_for_variant(package, package_name, package_dir, previews_dir)
    for v in variants:
        copy_previews_for_variant(v, package_name, package_dir, previews_dir)

def copy_thumbnail_for_variant(variant, package_name, package_dir, thumbnails_dir):
    if not 'thumbnail' in variant:
        return

    thumb_src = os.path.join(package_dir, variant['thumbnail'])
    thumb_dst = os.path.join(thumbnails_dir, package_name + '_' + variant['thumbnail'])

    dir = os.path.dirname(thumb_dst)
    if not os.path.isdir(dir):
        os.makedirs(dir)
    if os.path.exists(thumb_src):
        shutil.copy2(thumb_src, thumb_dst)

def copy_thumbnails_for_package(package, variants, package_name, package_dir, thumbnails_dir):
    copy_thumbnail_for_variant(package, package_name, package_dir, thumbnails_dir)

    # and now each variant in turn
    for v in variants:
        copy_thumbnail_for_variant(v, package_name, package_dir, thumbnails_dir)

def process_aircraft_dir(name, repo_path):
    global includes
    global download_base
    global output_dir
    global valid_zips
    global previews_dir

    aircraft_dir = os.path.join(repo_path, name)
    if not os.path.isdir(aircraft_dir):
        return

    (package, variants) = catalog.scan_aircraft_dir(aircraft_dir, includes)
    if package == None:
        print "skipping:", name, "(no -set.xml files)"
        return

    print "%s:" % name,

    package_node = catalog.make_aircraft_node(name, package, variants, download_base)

    download_url = download_base + name + '.zip'
    thumbnail_url = download_base + 'thumbnails/' + name + '_' + package['thumbnail']

    # get cached md5sum if it exists
    md5sum = get_xml_text(md5sum_root.find(str('aircraft_' + name)))

    # now do the packaging and rev number stuff
    dir_mtime = scan_dir_for_change_date_mtime(aircraft_dir)
    if repo_type == 'svn':
        rev = last_change_date_svn(aircraft_dir)
    else:
        d = datetime.datetime.utcfromtimestamp(dir_mtime)
        rev = d.strftime("%Y%m%d")
    package_node.append( catalog.make_xml_leaf('revision', rev) )
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
    package_node.append( catalog.make_xml_leaf('md5', md5sum) )
    package_node.append( catalog.make_xml_leaf('file-size-bytes', filesize) )

    # handle md5sum cache
    node = md5sum_root.find('aircraft_' + name)
    if node != None:
        node.text = md5sum
    else:
        md5sum_root.append( catalog.make_xml_leaf('aircraft_' + name, md5sum) )

    # handle thumbnails
    copy_thumbnails_for_package(package, variants, name, aircraft_dir, thumbnail_dir)

    catalog_node.append(package_node)

    # copy previews for the package and variants into the
    # output directory
    copy_previews_for_package(package, variants, name, aircraft_dir, previews_dir)

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
if not download_base.endswith('/'):
    download_base += '/'

output_dir = get_xml_text(config_node.find('local-output'))
if output_dir == '':
    output_dir = os.path.join(args.dir, 'output')
if not os.path.isdir(output_dir):
    os.mkdir(output_dir)

thumbnail_dir = os.path.join(output_dir, 'thumbnails')
if not os.path.isdir(thumbnail_dir):
    os.mkdir(thumbnail_dir)

previews_dir = os.path.join(output_dir, 'previews')
if not os.path.isdir(previews_dir):
    os.mkdir(previews_dir)

tmp = os.path.join(args.dir, 'zip-excludes.lst')
zip_excludes = os.path.realpath(tmp)

for i in config_node.findall("include-dir"):
    path = get_xml_text(i)
    if not os.path.exists(path):
        print "Skipping missing include path:", path
        continue
    includes.append(path)

# freshen repositories
if args.no_update:
    print 'Skipping repository updates.'
else:
    cwd = os.getcwd()
    for scm in scm_list:
        repo_type = get_xml_text(scm.find('type'))
        repo_path = get_xml_text(scm.find('path'))
        includes.append(repo_path)

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

        # process each aircraft in turn
        process_aircraft_dir(name, repo_path)

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
