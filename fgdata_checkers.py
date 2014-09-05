#!/usr/bin/env python3
from __future__ import print_function#defaults to Python 3, but should also work in 2.7
"""Functions for checking fgdata for various problems (and one for creating smaller/split versions of it)

By Rebecca Palmer"""
import os
import os.path
import re
from collections import defaultdict
import subprocess
import math
import tarfile
import gzip
import shutil
try:
    devnull=subprocess.DEVNULL#hide annoying nvcompress messages
except (AttributeError,NameError):#pre-3.3 Python
    devnull=None
def path_join(*args):
    """Unlike plain os.path.join, this doesn't add a trailing / if the last component is empty"""
    return os.path.normpath(os.path.join(*args))
def rfilelist(path,exclude_dirs=[]):
    """Dict of files/sizes in path, including those in any subdirectories (as relative paths)"""
    files=defaultdict(int)
    if not os.path.exists(path):
        return files
    dirs=[""]
    while dirs:
        cdir=dirs.pop()
        cdirfiles=os.listdir(path_join(path,cdir))
        for file in cdirfiles:
            if os.path.isdir(path_join(path,cdir,file)):
                if path_join(cdir,file) not in exclude_dirs:
                    dirs.append(path_join(cdir,file))
            else:
                files[path_join(cdir,file)]=os.path.getsize(path_join(path,cdir,file))
    return files
def strip_comments(text,comment_types=None,filename=None):
    """Remove comments from text
    Assumes comments don't nest (including different types of comments: will be wrong for e.g. /* aaa // bbb */ will-remove-this in C++ if // are removed first)
    Doesn't check for being inside a string literal, and doesn't check for line-start * in C /* ... */"""
    if comment_types is None:
        if filename is None:
            raise TypeError("must give either filename or comment_types")
        if os.path.splitext(filename)[1] in (".xml",".eff"):
            comment_types=(("<!--","-->",""),)
        elif os.path.splitext(filename)[1] in (".c",".cpp",".cxx",".h",".hpp",".hxx",".frag",".vert"):
            comment_types=(("//","\n","\n"),("/*","*/",""))
        elif os.path.splitext(filename)[1] in (".nas",):
            comment_types=(("#","\n","\n"),)
        else:
            comment_types=[]
    if type(text) in (bytes,bytearray):
        comment_types=[[bytes(c,encoding="ascii") for c in ct] for ct in comment_types]
    for comment_type in comment_types:
        text=text.split(comment_type[0],maxsplit=1)[0]+comment_type[2].join(s.split(comment_type[1],maxsplit=1)[1] for s in text.split(comment_type[0])[1:] if comment_type[1] in s)
    return text
def files_used(pattern,path,exclude_dirs=[],filelist=None,filetypes=None,relative_path=False):
    """Files used by an element matching pattern, in a file in path or filelist"""
    textures=[]
    if filelist is None:
        filelist=rfilelist(path,exclude_dirs).keys()
    if filetypes is not None:
        filelist=[f for f in filelist if os.path.splitext(f)[1] in filetypes]
    texfind=re.compile(pattern)
    for file in filelist:
        try:
            f=open(path_join(path,file),'r',errors='replace')
        except FileNotFoundError:
            continue
        for line in f:
            tex=texfind.search(line)
            if tex:
                if relative_path:
                    textures.append(os.path.normpath(path_join(os.path.dirname(file),tex.group(1).replace('\\','/'))))
                else:
                    textures.append(os.path.normpath(tex.group(1).replace('\\','/')))
    return textures
def find_unused_textures(basedir,output_lists=True,grep_check=False,output_rsync_rules=False,output_comparison_strips=False, output_removal_commands=False,return_used_noregions=False):
    """Checks if any textures are unused (wasting space), and if any textures are only available as .dds (not recommended in the source repository, as it is a lossy-compressed format)

Set basedir to your fg-root, and enable the kind(s) of output you want:
output_lists prints lists of unused textures, and of dds-only textures
grep_check checks for possible use outside the normal directories; requires Unix shell
output_rsync_rules prints rsync rules for excluding unused textures from the release flightgear-data.  Warning: if you use this, re-run this script regularly, in case they start being used
output_comparison_strips creates thumbnail strips, unused_duplicate.png/unused_dds.png/high_low.png, for visually checking whether same-name textures are the same (remove the unused one entirely) or different (move it to Unused); requires imagemagick or graphicsmagick
output_removal_commands creates another script, delete_unused_textures.sh, which will remove unused textures when run in a Unix shell"""

    false_positives=set(['buildings-lightmap.png','buildings.png','Credits','Globe/00README.txt', 'Globe/01READMEocean_depth_1png.txt', 'Globe/world.topo.bathy.200407.3x4096x2048.png','Trees/convert.pl','Splash1.png','Splash2.png','Splash3.png','Splash4.png','Splash5.png'])#these either aren't textures, or are used where we don't check; 'unknown.rgb','Terrain/unknown.rgb' are also referenced, but already don't exist
    used_textures=set(files_used(path=path_join(basedir,'Materials'),pattern=r'<(?:texture|object-mask|tree-texture).*?>(\S+?)</(texture|object-mask|tree-texture)'))|false_positives
    used_textures_noregions=set(files_used(path=path_join(basedir,'Materials'),exclude_dirs=['regions'],pattern=r'<(?:texture|object-mask|tree-texture).*?>(\S+?)</(texture|object-mask|tree-texture)'))|false_positives#this pattern matches a <texture> (possibly with number), <tree-texture> or <object-mask> element
    used_effectslow=set(files_used(path=path_join(basedir,'Effects'),pattern=r'image.*?>[\\/]?Textures[\\/](\S+?)</.*?image'))|set(files_used(path=path_join(basedir,'Materials'),pattern=r'<building-(?:texture|lightmap).*?>Textures[\\/](\S+?)</building-(?:texture|lightmap)'))#Effects (<image>), and Materials <building-texture>/<building-lightmap>, explicitly includes the Textures/ or Textures.high/
    used_effectshigh=set(files_used(path=path_join(basedir,'Effects'),pattern=r'image.*?>[\\/]?Textures.high[\\/](\S+?)</.*?image'))|set(files_used(path=path_join(basedir,'Materials'),pattern=r'<building-(?:texture|lightmap).*?>Textures.high[\\/](\S+?)</building-(?:texture|lightmap)'))
    high_tsizes=rfilelist(path_join(basedir,'Textures.high'))
    high_textures=set(high_tsizes.keys())
    low_tsizes=rfilelist(path_join(basedir,'Textures'),exclude_dirs=['Sky','Unused'])#sky textures are used where we don't check
    low_textures=set(low_tsizes.keys())
    only_high=high_textures-low_textures
    used_noreg_onlyhigh=(only_high&used_textures_noregions)|used_effectshigh
    used_noreg_onlyhighsize=sum(high_tsizes[t] for t in used_noreg_onlyhigh)
    used_noreg_low=(low_textures&used_textures_noregions)|used_effectslow
    used_noregions=used_textures_noregions|used_effectshigh|used_effectslow
    used_noreg_lowsize=sum(low_tsizes[t] for t in used_noreg_low)
    used_noreg_defsize=sum(low_tsizes[t] for t in (used_textures_noregions-high_textures)|used_effectslow)+sum(high_tsizes[t] for t in used_textures_noregions|used_effectshigh)
    used_defsize=sum(low_tsizes[t] for t in (used_textures-high_textures)|used_effectslow)+sum(high_tsizes[t] for t in used_textures|used_effectshigh)
    unused=(high_textures|low_textures)-used_textures-used_effectslow-used_effectshigh
    t_size=lambda tset: sum(high_tsizes[t] for t in tset)+sum(low_tsizes[t] for t in tset)
    missing=(used_textures-(high_textures|low_textures))|(used_effectslow-low_textures)|(used_effectshigh-high_textures)
    if missing:
        raise ValueError("Some used textures not found: "+repr(missing))
    sourceless=[f for f in (high_textures|low_textures) if (f[-4:]==".dds" and f[:-4]+".png" not in high_textures and (f in high_textures or f[:-4]+".png" not in low_textures) )]+['Terrain/airport.dds']#airport.dds isn't the same as airport.png; crop-colors.dds/cropgrass-colors.dds/rock-colors.dds/forest-colors.dds also differ but only in strip width, which doesn't matter as they are 1D color strips
    sourceless_used=set(sourceless)-unused
    needed_as_source=[f for f in unused if (f[-4:]!=".dds" and f[:-4]+".png" in (used_textures|used_effectslow|used_effectshigh) or f[:-4]+".dds" in (used_textures|used_effectslow|used_effectshigh))]+['Runway/designation_letters.svg']
    known_non_duplicates=['deciduous.png','drycrop.png','irrcrop.png','marsh1.png','gravel.png','Town.png','grass.png','mixedcrop.png','resgrid.png']+['glacier.png','rock.png','cropgrass.png']#first group real winter textures, second group unrelated textures
    unused_duplicate=[f for f in unused if (f[0:14]=="Terrain.winter" and "Terrain"+f[14:] in (high_textures|low_textures) and f[15:] not in known_non_duplicates)]
    unused_dds=set(f for f in (unused-set(unused_duplicate)) if (f[-4:]==".dds" and f[:-4]+".png" in (high_textures|low_textures) and f!='Terrain/airport.dds'))#airport.dds isn't the same as airport.png; crop-colors.dds/cropgrass-colors.dds/rock-colors.dds/forest-colors.dds also differ but only in strip width, which doesn't matter as they are 1D color strips
    unused_other=unused-set(unused_duplicate)-set(unused_dds)-set(needed_as_source)
    known_highlow_mismatch=set(['Terrain.winter/mixedcrop4.png','Terrain.winter/cropgrass3.png','Terrain.winter/drycrop4.png','Terrain.winter/irrcrop2.png','Terrain.winter/drycrop1.png','Terrain.winter/drycrop3.png','Terrain.winter/mixedcrop1.png','Terrain.winter/ mixedforest2.png','Terrain.winter/cropgrass2.png','Terrain.winter/cropgrass1.png','Terrain.winter/tundra.png','Terrain.winter/mixedforest3.png','Terrain.winter/shrub2.png','Terrain.winter/drycrop2.png','Terrain.winter/deciduous1.png','Terrain.winter/ mixedcrop3.png','Terrain.winter/naturalcrop1.png']+['Terrain.winter/tundra3.png','Terrain.winter/forest1c.png','Terrain.winter/herbtundra.png']+['Terrain/grass_rwy.dds','Terrain/cropwood.dds','Terrain/herbtundra.dds','Terrain/irrcrop.dds','Terrain/shrub.dds','Terrain.winter/mixedforest.png','Runway/pa_taxiway.png','Runway/pc_taxiway.png'])#first group are different degrees of snow cover on the same base texture, last group unrelated textures, middle group hard to tell; p{a,c}_taxiway (only low-res has side lines) are also mismatched in .dds, but as each .dds matches its size .png, only the .png needs to be kept in Unused
    lowres_maybe_source=['Terrain/lava1.png','Terrain/lava2.png','Terrain/lava3.png','Terrain/sand4.png','Terrain/sand5.png','Terrain/sand6.png']#these are clearly related, but the high-res version has unnatural-looking high-frequency noise, suggesting that the low-res version might be the original: keep it
    unused_dds_matchhigh=set(f for f in (unused_dds&known_highlow_mismatch) if f[:-4]+".png" not in low_textures)
    unused_dds_matchlow=set(f for f in (unused_dds&known_highlow_mismatch) if f[:-4]+".png" not in high_textures)
    low_unneeded=(high_textures&low_textures)-used_effectslow-unused-set(lowres_maybe_source)
    low_unneeded_duplicate=low_unneeded-set(known_highlow_mismatch)
    low_unneeded_nondup=low_unneeded&set(known_highlow_mismatch)
    def image_check_strip(basedir,index_fname,ilist1,ilist2=None,size=128):
        """Generate two rows of thumbnails, for easy visual comparison (between the two lists given, or if a single list is given, between low and high resolution)"""
        if ilist2 is None:
            ipairs=[[path_join(basedir,'Textures',f),path_join(basedir,'Textures.high',f)] for f in ilist1]
        else:
            ipairs=[]
            for f1,f2 in zip(ilist1,ilist2):
                if f1 in low_textures:
                    ipairs.append([path_join(basedir,'Textures',f1),path_join(basedir,'Textures',f2) if f2 in low_textures else path_join(basedir,'Textures.high',f2)])
                if f1 in high_textures:
                    ipairs.append([path_join(basedir,'Textures.high',f1),path_join(basedir,'Textures.high',f2) if f2 in high_textures else path_join(basedir,'Textures',f2)])
        ilist_f=[f[0] for f in ipairs]+[f[1] for f in ipairs]
        subprocess.call(['montage','-label',"'%f'"]+ilist_f+['-tile','x2','-geometry',str(size)+'x'+str(size)]+[index_fname])
    def rsync_rules(basedir,flist,include=False,high=None):
        """Output rsync rules to exclude/include the specified textures from high/low/both (high=True/False/None) resolutions"""
        for f in flist:
            if high!=True and f in low_textures:
                print("+" if include else "-",path_join('/fgdata/Textures',f))
            if high!=False and f in high_textures:
                print("+" if include else "-",path_join('/fgdata/Textures.high',f))
    def removal_command(basedir,flist,high=None):
        """Return command to delete the specified textures from high/low/both (high=True/False/None) resolutions"""
        if not flist:
            return ""
        a="rm"
        for f in flist:
            if high!=True and f in low_textures:
                a=a+" "+path_join('Textures',f)
            if high!=False and f in high_textures:
                a=a+" "+path_join('Textures.high',f)
        a=a+"\n"
        return a
    def move_command(basedir,flist,high=None,comment=False):
        """Return command to move the specified textures to Unused from high/low/both (high=True/False/None) resolutions"""
        if not flist:
            return ""
        dirset_low=set() if high==True else set(os.path.dirname(f) for f in set(flist)&low_textures)
        dirset_high=set() if high==False else set(os.path.dirname(f) for f in set(flist)&high_textures)
        a=""
        for d in dirset_low:
            a=a+("#" if comment else "")+"mv --target-directory="+path_join("Textures/Unused",d)+" "+(" ".join(path_join("Textures",f) for f in flist if (os.path.dirname(f)==d and f in low_textures)))+"\n"
        for d in dirset_high:
            a=a+("#" if comment else "")+"mv --target-directory="+path_join("Textures/Unused",d+".high")+" "+(" ".join(path_join("Textures.high",f) for f in flist if (os.path.dirname(f)==d and f in high_textures)))+"\n"
        return a
    if output_comparison_strips:
        image_check_strip(basedir,"unused_duplicate.png",unused_duplicate,["Terrain"+f[14:] for f in unused_duplicate])
        image_check_strip(basedir,"unused_dds.png",unused_dds,[f[:-4]+".png" for f in unused_dds])
        image_check_strip(basedir,"high_low.png",high_textures&low_textures)
        #image_check_strip(basedir,"high_low2.png",[f for f in high_textures&low_textures if (f[0:14]=="Terrain.winter" or "_taxiway." in f or "lava" in f or "sand" in f)],size=512)#closer look at the doubtful cases
    if output_lists:
        print("\n\nunused-winter same as normal:",sorted(unused_duplicate),"\nsize=",t_size(unused_duplicate),"\n\nunused-dds with matching png:",sorted(unused_dds),"\nsize=",t_size(unused_dds),"\n\nunused-unique:",sorted(unused_other),"\nsize=",t_size(unused_other),"\n\nnot directly used but keep as source:",sorted(needed_as_source),"\nsize=",t_size(needed_as_source),"\n\nunused low, matches high:",sorted(low_unneeded_duplicate),"\nsize=",sum(low_tsizes[f] for f in low_unneeded_duplicate),"\n\nunused low, unique:",sorted(low_unneeded_nondup),"\nsize=",sum(low_tsizes[f] for f in low_unneeded_nondup),"\n\nall non-sky textures size=",sum(high_tsizes.values())+sum(low_tsizes.values()),"used size=",used_defsize,"used no-regions size=",used_noreg_defsize,"\n\nnot found:",sorted(missing),"\n\n.dds only/highest-res:",sorted(sourceless),"\n\n.dds only/highest-res, used:",sorted(sourceless_used))
        #not really meaningful after removing low-res duplicates: ,"\n\nused high-only, not regions:",sorted(used_noreg_onlyhigh),"\nsize=",used_noreg_onlyhighsize,"these+used low (i.e. minimal flightgear-data) size=",used_noreg_onlyhighsize+used_noreg_lowsize
    if grep_check:
        unused_f=[os.path.basename(f) for f in unused]
        all_f=[os.path.basename(f) for f in (high_textures|low_textures)]
        print("\n\nPossible use outside main search:")#used to set false_positives
        subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=.git","-e","("+")|(".join(unused)+")","/home/rnpalmer/fs_dev/git/fgdata","/home/rnpalmer/fs_dev/git/flightgear","/home/rnpalmer/fs_dev/git/simgear"])#everywhere using full names
        subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=Textures.high","--exclude-dir=Models","--exclude-dir=Materials","--exclude-dir=Effects","--exclude-dir=.git","-e","("+")|(".join(all_f)+")","/home/rnpalmer/fs_dev/git/fgdata","/home/rnpalmer/fs_dev/git/flightgear","/home/rnpalmer/fs_dev/git/simgear"])#restricted (to avoid false positives from Terrain.winter vs Terrain) using filenames
        subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=Textures.high","--exclude-dir=Models","--exclude-dir=Materials","--exclude-dir=Effects","--exclude-dir=.git","-e",'[."\']dds',"/home/rnpalmer/fs_dev/git/fgdata","/home/rnpalmer/fs_dev/git/flightgear","/home/rnpalmer/fs_dev/git/simgear"])#check for programmatic .png -> .dds swap; none found
        print("\n\nUse of sourceless textures:")
        subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=.git","-e","("+")|(".join(sourceless)+")","/home/rnpalmer/fs_dev/git/fgdata","/home/rnpalmer/fs_dev/git/flightgear","/home/rnpalmer/fs_dev/git/simgear"])
    if output_rsync_rules:
        print("\n\nFull flightgear-data:\n")
        rsync_rules(basedir,unused)
        rsync_rules(basedir,low_unneeded,high=False)
        print("\n\nMinimal flightgear-data:\n")
        rsync_rules(basedir,low_textures-used_noreg_low,high=False)
        rsync_rules(basedir,high_textures-used_noreg_onlyhigh,high=True)
    if output_removal_commands:
        r_script=open('delete_unused_textures.sh','w')
        r_script.write("cd "+basedir+"\n")
        r_script.write("#Unused duplicates\n")
        r_script.write(removal_command(basedir,unused_duplicate))
        r_script.write("#Unused .dds versions\n")
        r_script.write(removal_command(basedir,unused_dds-unused_dds_matchhigh,high=False))
        r_script.write(removal_command(basedir,unused_dds-unused_dds_matchlow,high=True))
        r_script.write("#Unused reduced-resolution versions\n")
        r_script.write(removal_command(basedir,low_unneeded_duplicate|(unused_other&high_textures&low_textures)-set(lowres_maybe_source),high=False))
        r_script.write("#Unused unique .png (move to Unused)\n")
        r_script.write("\n".join(["mkdir -p Textures/Unused/"+d for d in ['Terrain','Terrain.winter','Trees','Terrain.high','Terrain.winter.high','Trees.high','Runway','Water']])+"\n")
        r_script.write(move_command(basedir,[f for f in unused_other&high_textures if (f[-4:]!=".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True))
        r_script.write(move_command(basedir,[f for f in (unused_other-high_textures)|low_unneeded_nondup if (f[-4:]!=".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=False))
        r_script.write("#Unused unique .dds\n")
        r_script.write("#It is my opinion that these should go, but if you'd prefer to move them to Unused I won't argue further\n")
        r_script.write(removal_command(basedir,[f for f in (unused_other&high_textures)|unused_dds_matchlow if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True))
        r_script.write(removal_command(basedir,[f for f in (unused_other-high_textures)|low_unneeded_nondup|unused_dds_matchhigh if f[-4:]==".dds"],high=False))
        r_script.write(move_command(basedir,[f for f in (unused_other&high_textures)|unused_dds_matchlow if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True,comment=True))
        r_script.write(move_command(basedir,[f for f in (unused_other-high_textures)|low_unneeded_nondup|unused_dds_matchhigh if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=False,comment=True))
        r_script.close()
    if return_used_noregions:
        return used_noregions|set([path_join('Sky',f) for f in rfilelist(path_join(basedir,'Textures/Sky'))])
def find_locally_unused_models(basedir):
    """Find models not used in the base scenery (these do need to be in Terrasync as they may well be used in other locations, but don't need to be in the base flightgear-data package)
    Known bug: doesn't search everywhere: check /Nasal,.eff <image>,<inherits-from>,/(AI/)Aircraft not referenced in AI scenarios, unusual tags in Aircraft/Generic/Human/Models/walker.xml,HLA/av-aircraft.xml,/Environment,MP/aircraft_types.xml,preferences.xml"""
    models_allfiles={path_join('Models',f):s for f,s in rfilelist(path_join(basedir,'Models')).items()}
    t_size=lambda flist: sum(models_allfiles[f] for f in flist if f in models_allfiles)
    used_models=set(files_used(path=path_join(basedir,'Scenery'),filetypes=".stg",pattern=r'OBJECT_SHARED (\S+?) '))|set(files_used(path=path_join(basedir,'AI'),exclude_dirs=["Aircraft","Traffic"],pattern=r'<model>[\\/]?(\S+?)</model>'))|set(f for f in files_used(path=path_join(basedir,'Materials'),filetypes=".xml",pattern=r'<path>[\\/]?(\S+?)</path>') if f[-4:]==".xml")
    n=0
    while n!=len(used_models):
        n=len(used_models)
        used_models=used_models|set(f for f in files_used(path=basedir,filelist=used_models,filetypes=".xml",pattern=r'<path>[\\/]?(\S+?)</path>') if f[-4:]==".xml")
    used_textures=set(files_used(path=basedir,filelist=used_models,filetypes=".ac",pattern=r'texture "(\S+?)"',relative_path=True))|set(files_used(path=basedir,filelist=used_models,filetypes=".xml",pattern=r'<texture>[\\/]?(\S+?)</texture>',relative_path=True))
    extra_used_models=set()
    for f1 in used_models:
        if f1[-4:]!=".xml":
            continue
        for f2 in files_used(path=basedir,filelist=[f1],pattern=r'<path>[\\/]?(\S+?)</path>',relative_path=True):
            if f2[-3:]!=".ac":
                continue
            extra_used_models=extra_used_models|set([f2])
            p2=[f for f in files_used(path=basedir,filelist=[f1],pattern=r'<texture-path>[\\/]?(\S+?)</texture-path>',relative_path=True)]
            if len(p2)==0:
                p2=[os.path.dirname(f1)]
            if len(p2)!=1:
                print("non-unique/not found:",f1,f2,p2)
                continue
            try:
                used_textures=used_textures|set(os.path.normpath(path_join(p2[0],f)) for f in files_used(path=basedir,filelist=[f2],filetypes=".ac",pattern=r'texture "(\S+?)"'))
            except (IOError,OSError):
                print("not found",f1,f2,p2)
    used_models=used_models|extra_used_models
    unused=set(models_allfiles.keys())-(used_models|used_textures)
    missing=set(f for f in (used_models|used_textures) if ((f.startswith('Models') and f not in models_allfiles.keys()) or not os.path.isfile(path_join(basedir,f))))
    print("used\n",sorted(used_models),"\nsize=",t_size(used_models),"\n\n",sorted(used_textures),"\nsize=",t_size(used_textures),"\n\nunused\n",sorted(unused),"\nsize=",t_size(unused),"\n\nmissing\n",sorted(missing),"\nsize=",t_size(missing))

def size_by_type(path,exclude_dirs=[]):
    """Dict of total file size by file extension"""
    files=rfilelist(path,exclude_dirs)
    size_totals=defaultdict(int)
    for filename,size in files.items():
        file_ext=os.path.splitext(filename)[1]
        if file_ext==".gz":
            file_ext=os.path.splitext(os.path.splitext(filename)[0])[1]+file_ext
        size_totals[file_ext]=size_totals[file_ext]+size
    return size_totals
def size_by_size(path,exclude_dirs=[],exts=[".png",".dds",".rgb"]):
    """Dict of total file size by individual file size range, of given extensions (empty list for all files)"""
    files=rfilelist(path,exclude_dirs)
    size_totals=defaultdict(int)
    for filename,size in files.items():
        file_ext=os.path.splitext(filename)[1]
        if (not exts) or (file_ext in exts):
            size_totals[2**math.frexp(size)[1]]=size_totals[2**math.frexp(size)[1]]+size
    return size_totals
def fgdata_size(path,dirs_to_list=["AI/Aircraft","AI/Traffic","Aircraft","Models","Scenery","Textures","Textures.high"],exclude_dirs=None,compressed_size=False,num_types=3):
    if dirs_to_list is None:
        dirs_to_list=[d for d in os.listdir(path) if os.path.isdir(path_join(path,d))]
    if exclude_dirs is None:
        if os.path.exists(path_join(path,".git")):
            exclude_dirs=[".git","Aircraft"]
        else:
            exclude_dirs=[]
    total_compressed_size=0
    exclude_list=[[]]*len(dirs_to_list)+[dirs_to_list+exclude_dirs]+[exclude_dirs]
    names_list=dirs_to_list+["other","all"]
    for n,dir1 in enumerate(dirs_to_list+["",""]):
        size_totals=size_by_type(path_join(path,dir1),exclude_list[n])
        print(names_list[n],sorted(size_totals.items(),key=lambda x:-x[1])[:num_types],"total",sum(size_totals.values()))
        if compressed_size:
            if names_list[n]=="all":
                print("compressed size",total_compressed_size)
                continue
            targz=tarfile.open("fgdata_sizetest_temp.tar.gz",mode="w:gz")
            for file in rfilelist(path_join(path,dir1),exclude_list[n]):
                targz.add(path_join(path,dir1,file))
            targz.close()
            print("compressed size",os.path.getsize("fgdata_sizetest_temp.tar.gz"))
            total_compressed_size=total_compressed_size+os.path.getsize("fgdata_sizetest_temp.tar.gz")

def create_reduced_fgdata(input_path,output_path,split_textures=True,exclude_parts=[],include_aircraft=['UIUC','777','777-200','b1900d','CitationX','ZLT-NT','dhc2','Cub','sopwithCamel','f-14b','ASK13','bo105','Dragonfly','SenecaII','A6M2'],dirs_to_downsample=(),dirs_to_compress=(),compressed_format=".dds",downsample_min_filesize=30000):
    """Create a smaller, reduced-quality flightgear-data package
Can downsample textures 50%, change texture format, and/or omit sections (region-specific textures, aircraft, AI traffic)
Downsampling and format change require imagemagick or graphicsmagick (for convert) and libnvtt-bin (for nvcompress)

Optional parts, use exclude_parts to omit:
ai: no background traffic, but tankers etc do still work
extra-textures (requires split_textures=True): no region-specific textures

The c172p and ufo are always included; other aircraft are added by include_aircraft

Texture downsampling: textures in dirs_to_downsample and larger than downsample_min_filesize downsampled 50%
Texture format conversion: textures in dirs_to_compress and larger than downsample_min_filesize converted to compressed_format
Suggested dirs_to_downsample:
3.2: ('Textures.high/Terrain','Textures.high/Trees','Textures.high/Terrain.winter','AI/Aircraft','Models')
3.3: ('Textures/Terrain','Textures/Trees','Textures/Terrain.winter','AI/Aircraft','Models')
To do "everything" (a few are always skipped due to potential breakage), use dirs_to_compress=('',)

To put each section in its own directory (e.g. for building a Debian-style flightgear-data-* set of packages) use {0} in output_path, e.g.
python3 -c "import fgdata_checkers; fgdata_checkers.create_reduced_fgdata(input_path='/home/rnpalmer/fs_dev/git/fgdata',output_path='/home/rnpalmer/fs_dev/flightgear/data_split/debian/flightgear-data-{0}/usr/share/games/flightgear',include_aircraft=['UIUC','b1900d','CitationX','ZLT-NT','dhc2','Cub','sopwithCamel','f-14b','ASK13','bo105','Dragonfly','SenecaII','A6M2'])"
This creates separate preferences-regions.xml and preferences-noregions.xml files for with and without regional textures; you need to handle symlinking preferences.xml to the correct one
"""
    texture_filetypes={".png":"PNG",".dds":"DDS",".jpg":"JPEG"}#,".rgb":"SGI" loses cloud transparency
    textureuser_types={".eff",".xml",".ac",".nas"}
    binary_types={".png",".dds",".rgb",".RGB",".jpg",".wav",".WAV",".btg.gz",".zip",".tar.gz"}#don't search these for texture name replacement
    """Textures named directly in flightgear/simgear code:
gui/images/shadow.png,gui/cursor-spin-cw.png (probably safest to treat this as gui/*, they're all small)
Textures/Globe/world.topo.bathy.200407.3x4096x2048.png
Textures/buildings.png,Textures/buildings-lightmap.png
Textures/Sky/*
Textures/Splash*.png
unknown.rgb (probably Textures/ or Textures/Terrain/, neither exists)
Aircraft/Instruments/Textures/nd-symbols.png (doesn't actually exist),Aircraft/Instruments/Textures/compass-ribbon.rgb,Aircraft/Instruments/Textures/od_wxradar.rgb,Aircraft/Instruments/Textures/od_wxradar.rgb,Aircraft/Instruments/Textures/wxecho.rgb,Aircraft/Instruments/Textures/od_groundradar.rgb (doesn't actually exist)
also, Aircraft/{Instruments,Instruments-3d,Generic} may be used by downloaded aircraft, and Docs images are used in .html
Nasal (Canvas map) probably wouldn't break anything, but guessing it's a bad idea visually"""
    no_compress_pattern=re.compile(r'mask|light|relief|nmap|nm\.|normal|^Splash[0-9].png$|^buildings.png$|^buildings-lightmap.png$|^world.topo.bathy.200407.3x4096x2048.png$')#edge blurring from lossy compression may break masks, and this script doesn't know how to create DDS normal maps
    no_compress_dirs=("gui","Docs","webgui","Nasal","Textures/Sky","Aircraft/Instruments","Aircraft/Instruments-3d","Aircraft/Generic")
    exclude_dirs=[".git","Textures/Unused"]
    exclude_unnamed_subdirs=["Aircraft"]#these are a separate mechanism from subtree_class/exclude_parts mostly to save time (subtree_class still fully scans excluded directories because the class may change again further down the tree, e.g. AI/Aircraft ai -> performancedb.xml base; these don't)
    subtree_class={"Aircraft/c172p":"base","Aircraft/Generic":"base","Aircraft/Instruments":"base","Aircraft/Instruments-3d":"base","Aircraft/ufo":"base","Textures":"textures","Textures.high":"textures","AI/Aircraft":"ai","AI/Traffic":"ai","AI/Aircraft/performancedb.xml":"base","Scenery":"scenery","Models":"models"}
    for aircraft in include_aircraft:
        if "Aircraft/"+aircraft not in subtree_class:
            subtree_class["Aircraft/"+aircraft]="aircraft"
    include_files=[]
    if split_textures:
        base_texture_files=[]
        for t in find_unused_textures(input_path,return_used_noregions=True):
            base_texture_files.extend([path_join("Textures",t),path_join("Textures.high",t)])
    #no longer a significant problem with exclude_dirs: if os.path.exists(path_join(input_path,".git")):
        #print(input_path,"appears to be a git clone; this will work, but the result will be larger than starting from a standard flightgear-data package.\nTo create this use (adjusting paths as necessary) rsync -av --filter=\"merge /home/rnpalmer/fs_dev/git/fgmeta/base-package.rules\" ~/fs_dev/git/fgdata ~/fs_dev/flightgear/data_full")
    if os.path.exists(output_path.format("base")) and os.listdir(output_path.format("base")):
        print("output path",output_path,"non-empty, aborting to avoid data loss\nIf you did want to lose its previous contents, run:\nrm -r",output_path,"\nthen re-run this script")
        return
    if compressed_format==".jpg":
        print("Warning: selected compression format does not support transparency")
    compress_names=set()
    if dirs_to_compress:#need this preliminary pass to get names to change in .xml,etc
        no_compress_names=set()
        dirs={"":"base"}
        while dirs:
            cdir,cclass=dirs.popitem()
            cdirfiles=os.listdir(path_join(input_path,cdir))
            for file in cdirfiles:
                fclass=subtree_class.get(path_join(cdir,file),cclass)
                if os.path.isdir(path_join(input_path,cdir,file)):
                    if (path_join(cdir,file) not in exclude_dirs) and (cdir not in exclude_unnamed_subdirs or path_join(cdir,file) in subtree_class):
                        dirs[path_join(cdir,file)]=fclass
                else:#file
                    compress_this=cdir.startswith(dirs_to_compress) and (os.path.splitext(file)[1] in texture_filetypes) and (os.path.getsize(path_join(input_path,cdir,file))>downsample_min_filesize) and not no_compress_pattern.search(file) and not cdir.startswith(no_compress_dirs) and (file not in no_compress_names) and (not os.path.exists(path_join(input_path,cdir,os.path.splitext(file)[0]+compressed_format)))
                    if compress_this:
                        compress_names.add(file)
                    else:
                        no_compress_names.add(file)
                        compress_names.discard(file)#if there are two with the same name in different directories, compress both or neither, to simplify name replacement
    compress_names_find=re.compile(('(?<=["\'>/\\\\ \\n])('+'|'.join(re.escape(f) for f in compress_names)+')($|(?=["\'< \\n]))').encode('utf-8'))
    compress_names_replace=lambda mf: os.path.splitext(mf.group(0))[0]+(compressed_format.encode('utf-8'))
    compress_names_find0=re.compile(('|'.join(re.escape(f) for f in compress_names)).encode('utf-8'))
    #print(compress_names,"\n\n",no_compress_names,"\n\n",'(?<=["\'>/\\\\ \\n])('+'|'.join(re.escape(f) for f in compress_names)+')($|(?=["\'< \\n]))',"\n\n",'|'.join(re.escape(f) for f in compress_names),"\n\n")
    dirs={"":"base"}
    while dirs:
        cdir,cclass=dirs.popitem()
        cdirfiles=os.listdir(path_join(input_path,cdir))
        for file in cdirfiles:
            fclass=subtree_class.get(path_join(cdir,file),cclass)
            if os.path.isdir(path_join(input_path,cdir,file)):
                if (path_join(cdir,file) not in exclude_dirs) and (cdir not in exclude_unnamed_subdirs or path_join(cdir,file) in subtree_class):
                    dirs[path_join(cdir,file)]=fclass
            else:#file
                if split_textures and fclass=="textures":
                    if path_join(cdir,file) in base_texture_files:
                        fclass="base-textures"
                    else:
                        fclass="extra-textures"
                if fclass in exclude_parts:
                    continue
                if not os.path.exists(path_join(output_path.format(fclass),cdir)):
                    os.mkdirs(path_join(output_path.format(fclass),cdir))
                downsample_this=(cdir.startswith(dirs_to_downsample)) and (os.path.splitext(file)[1] in texture_filetypes) and (os.path.getsize(path_join(input_path,cdir,file))>downsample_min_filesize)
                compress_this=(file in compress_names)
                if downsample_this or compress_this:
                    image_type=texture_filetypes[os.path.splitext(file)[1]]
                    output_image_type=compressed_format if compress_this else os.path.splitext(file)[1]
                    output_file=os.path.splitext(file)[0]+output_image_type
                    output_image_type=texture_filetypes[output_image_type]
                    if "{0}" in output_path and fclass=="base-textures":#downsampled in base-textures, full resolution in extra-textures
                        if not os.path.exists(path_join(output_path.format("extra-textures"),cdir)):
                            os.mkdirs(path_join(output_path.format("extra-textures"),cdir))
                        shutil.copy(path_join(input_path,cdir,file),path_join(output_path.format("extra-textures"),cdir,file))
                    if output_image_type=="DDS":# in Ubuntu, neither imagemagick nor graphicsmagick can write .dds
                        #doesn't work subprocess.call(["nvzoom","-s","0.5","-f","box",path_join(input_path,cdir,file),path_join(output_path.format(fclass),cdir,file)])
                        if subprocess.call(["convert",image_type+":"+path_join(input_path,cdir,file)]+(["-flip"] if ((image_type=="DDS")!=(output_image_type=="DDS")) else [])+(["-sample","50%"] if downsample_this else [])+["temp_reduced_size.png"]):#fails on DDS normal maps, so just copy them
                            retcode=None
                            shutil.copy(path_join(input_path,cdir,file),path_join(output_path.format(fclass),cdir,file))
                            if compress_this:
                                print("Error:")
                            print(path_join(cdir,file)," probably normal map")
                        else:
                            retcode=subprocess.call(["nvcompress","-bc3","temp_reduced_size.png",path_join(output_path.format(fclass),cdir,output_file)],stdout=devnull)
                    else:
                        retcode=subprocess.call(["convert",image_type+":"+path_join(input_path,cdir,file)]+(["-sample","50%"] if downsample_this else [])+[output_image_type+":"+path_join(output_path.format(fclass),cdir,output_file)])#we use sample rather than an averaging filter to not break mask/rotation/... maps
                else:#not to be downsampled/compressed
                    if os.path.splitext(file)[1] in binary_types:#just copy
                        retcode=None
                        shutil.copy(path_join(input_path,cdir,file),path_join(output_path.format(fclass),cdir,file))
                    else:#texture name replacement
                        retcode=None
                        file_in=open(path_join(input_path,cdir,file),'rb')
                        file_out=open(path_join(output_path.format(fclass),cdir,file),'wb')
                        file_str=file_in.read(None)
                        file_in.close()
                        (file_strout,num_matches)=compress_names_find.subn(compress_names_replace,file_str)
                        file_out.write(file_strout)
                        file_out.close()
                        #if ((os.path.splitext(file)[1] not in textureuser_types) and num_matches>0):
                            #print("Warning: ",num_matches," unexpected use(s) in ",path_join(cdir,file))
                        #if compress_names_find0.search(file_strout):
                            #print("Warning: unreplaced match(es) in ",path_join(cdir,file),compress_names_find0.search(file_strout).group(0))
                            """Warning: unreplaced match(es) in... correct rejections of match within a filename:
                            Aircraft/Instruments-3d/AN-APS-13.ac b'panel.png'
                            Aircraft/Instruments-3d/magneto-switch/mag_switch.ac b'black.png'
                            Nasal/canvas/map/Images/chart_symbols.svg b'wash.png'
                            Models/Airport/blast-deflector49m.ac b'generic.png'
                            Models/Airport/blast-deflector63m.ac b'generic.png'
                            Models/Industrial/oilrig09.ac b'yellow.png'
                            Models/Industrial/oilrig10.ac b'yellow.png'
                            Models/Industrial/oilrig09.ac.before-color-change b'yellow.png'
                            Models/Industrial/oilrig10.ac.before-color-change b'yellow.png'
                            Models/Maritime/Civilian/Tanker.ac b'black.png'
                            Models/Transport/flatcar.xml b'evergreen.png'
                            Models/Commercial/tower-grey-black.ac b'black.png'
                            Materials/base/materials-base.xml b'yellow.png'
                            
                            Warning: unexpected use(s) in...
                            Docs/README.local_weather.html (the only one that looke like an actual problem; hence, Docs is now skipped)
                            Nasal/canvas/map/Images/chart_symbols.svg (probably inkscape:export-filename, which are creator-specific absolute paths anyway, but now skipped)
                            oilrig09.ac.before-color-change,oilrig10.ac.before-color-chang,stbd_coaming_panel.ac.bak (presumably backup files)
                            """
                if retcode:
                    print("Error ",retcode," on ",path_join(cdir,file))
    if "{0}" in output_path:
        subprocess.call(["mv",path_join(output_path.format("base"),"preferences.xml"),path_join(output_path.format("base"),"preferences-regions.xml")])
    if "extra-textures" in exclude_parts or "{0}" in output_path:
        prefs_in=open(path_join(input_path,"preferences.xml"),'r')
        prefs_out=open(path_join(output_path.format("base"),"preferences-noregions.xml" if "{0}" in output_path else "preferences.xml"),'w')
        prefs_str=prefs_in.read(None)
        prefs_in.close()
        prefs_str=prefs_str.replace("Materials/regions/materials.xml","Materials/default/materials.xml")#turn off regional textures
        prefs_out.write(prefs_str)
        prefs_out.close()
def check_text_encoding(path,filelist=None,binary_types=(".png",".dds",".rgb",".RGB",".jpg",".wav",".WAV",".btg.gz",".xcf.gz",".xcf",".XCF","Thumbs.db",".blend",".bmp",".gif", ".3ds",".3DS",".pdf",".ttf",".txf",".htsvoice",".odt",".ods",".xls",".mp3",".zip",".tar.gz"),exclude_dirs=[".git","Timezone"]):
    """filelist is intended for quick testing: see fgdata_nonascii_filelist.py"""
    def err_context(err):
        start=max(err.object.rfind(b'\n',0,err.start)+1,err.start-30,0)
        end=min(err.object.find(b'\n',err.start),err.start+30,len(err.object))
        if end<0:#not found
            end=err.start+30
        return err.object[start:end]
    def dict_print(d):
        return "".join(i[0]+"\n\t"+str(i[1])+"\n\t"+(str(i[1],encoding="utf-8",errors="replace")+"\n\t"+str(i[1],encoding="latin-1") if type(i[1])==bytes else "")+"\n" for i in sorted(d.items()))
    if filelist is None:
        filelist=[f for f in rfilelist(path,exclude_dirs) if not f.endswith(tuple(binary_types))]
    utf8_files={}
    withnulls_files=[]
    othertext_files={}
    mislabeled_xml={}
    mislabeled_xml_nocomments={}
    xml_encoding_pattern=re.compile(r'<\?xml.*?encoding="(\S+?)".*?\?>')
    xml_noencoding_pattern=re.compile(r'<\?xml.*?\?>')
    utf8_files_nocomments={}
    othertext_files_nocomments={}
    for fname in filelist:
        if os.path.splitext(fname)[1]==".gz":
            fobj=gzip.open(path_join(path,fname),mode='rb')
        else:
            fobj=open(path_join(path,fname),mode='rb')
        fdata=fobj.read()
        if b"\0" in fdata:
            withnulls_files.append(fname)#two look like corrupted files: Aircraft/p51d/Resources/WIP/P-51D-25NA.ac (hangs gedit,large block of nulls in middle) Docs/Serial/nmeafaq.txt (block of nulls at end), rest are probably-binary types
            continue
        if os.path.splitext(fname)[1] in (".xml",".svg",".xhtml"):
            encoding_mark=xml_encoding_pattern.search(str(fdata.split(b'\n',maxsplit=1)[0],encoding="utf-8"))
            if encoding_mark:
                encoding_mark=encoding_mark.group(1)
                if encoding_mark not in ("utf-8","UTF-8","ISO-8859-1"):
                    mislabeled_xml_nocomments[fname]="unrecognised encoding "+encoding_mark
                    encoding_mark=None
            else:
                if xml_noencoding_pattern.search(str(fdata.split(b'\n',maxsplit=1)[0],encoding="utf-8")):
                    encoding_mark="utf-8"#XML standard allows either UTF-8 or UTF-16 (with BOM) in unlabeled files, but we only use -8
                else:
                    encoding_mark=None
                    #mislabeled_xml_nocomments[fname]="no xml header"
        else:
            encoding_mark=None
        try:
            fdata.decode(encoding="ascii")
            continue
        except UnicodeError as err:
            errline=err_context(err)
        try:
            fdata.decode(encoding="utf-8")
            utf8_files[fname]=errline
            if encoding_mark not in ("utf-8","UTF-8",None):
                mislabeled_xml[fname]=bytes(encoding_mark,encoding="ascii")+errline
        except UnicodeError as err:
            errline=err_context(err)
            othertext_files[fname]=errline
            if encoding_mark not in ("ISO-8859-1",None):
                mislabeled_xml[fname]=bytes(encoding_mark,encoding="ascii")+errline
        if os.path.basename(fname) in ("Read-Me.txt","README.txt","Readme.txt","readme.txt","LIS-MOI_GNU-GPL"):
            continue
        fdata_nocomments=strip_comments(fdata,filename=fname)
        if fdata_nocomments.startswith(bytes([0xef,0xbb,0xbf])) and fname not in mislabeled_xml:#UTF-8 BOM
            fdata_nocomments=fdata_nocomments[3:]
        try:
            fdata_nocomments.decode(encoding="ascii")
            continue
        except UnicodeError as err:
            errline=err_context(err)
        try:
            fdata_nocomments.decode(encoding="utf-8")
            if encoding_mark is None:
                utf8_files_nocomments[fname]=errline
            if encoding_mark not in ("utf-8","UTF-8",None):
                mislabeled_xml_nocomments[fname]=bytes(encoding_mark,encoding="ascii")+errline
        except UnicodeError as err:
            errline=err_context(err)
            if encoding_mark is None:
                othertext_files_nocomments[fname]=errline
            if encoding_mark not in ("ISO-8859-1",None):
                mislabeled_xml_nocomments[fname]=bytes(encoding_mark,encoding="ascii")+errline
    print("non-ASCII valid UTF-8:",dict_print(utf8_files),"\n\nother:",dict_print(othertext_files),"\n\nmislabeled/unrecognised",dict_print(mislabeled_xml),"\n\nwith nulls (binary or UTF-16/32):",sorted(withnulls_files),"\n\nnon-ASCII valid UTF-8 (outside BOM/comments):",dict_print(utf8_files_nocomments),"\n\nother (outside comments):",dict_print(othertext_files_nocomments),"\n\nmislabeled/unrecognised (outside comments)",dict_print(mislabeled_xml_nocomments))

