#!/usr/bin/env python3
from __future__ import print_function#defaults to Python 3, but should also work in 2.7

"""Script for checking if any textures are unused (wasting space), and if any textures are only available as .dds (not recommended in the source repository, as it is a lossy-compressed format)

Set basedir to your fg-root, and enable the kind(s) of output you want below:"""

#basedir='/usr/share/games/flightgear/'#Debian/Ubuntu installed default
output_lists=True#prints lists of unused textures, and of dds-only textures
grep_check=False#checks for possible use outside the normal directories; requires Unix shell
output_rsync_rules=False#prints rsync rules for excluding unused textures from the release flightgear-data.  Warning: if you use this, re-run this script regularly, in case they start being used
output_comparison_strips=False#creates thumbnail strips, unused_duplicate.png/unused_dds.png/high_low.png, for visually checking whether same-name textures are the same (remove the unused one entirely) or different (move it to Unused); requires ImageMagick/graphicsmagick
output_removal_commands=False#creates another script, delete_unused_textures.sh, which will remove unused textures when run in a Unix shell

import os
import os.path
import re
from collections import defaultdict
import subprocess

try:
    basedir
except NameError:
    print("basedir not set, please set it")

def rfilelist(path,exclude_dirs=[]):
    """Dict of files/sizes in path, including those in any subdirectories (as relative paths)"""
    files=defaultdict(int)
    dirs=[""]
    while dirs:
        cdir=dirs.pop()
        cdirfiles=os.listdir(os.path.join(path,cdir))
        for file in cdirfiles:
            if os.path.isdir(os.path.join(path,cdir,file)):
                if os.path.join(cdir,file) not in exclude_dirs:
                    dirs.append(os.path.join(cdir,file))
            else:
                files[os.path.join(cdir,file)]=os.path.getsize(os.path.join(path,cdir,file))
    return files
def textures_used(path,exclude_dirs=[],pattern=r'<(?:texture|object-mask|tree-texture).*?>(\S+?)</(texture|object-mask|tree-texture)'):
    """Textures used by a file in paths; default pattern matches a <texture> (possibly with number), <tree-texture> or <object-mask> element (for materials files)"""
    textures=[]
    matfiles=rfilelist(path,exclude_dirs).keys()
    texfind=re.compile(pattern)
    for file in matfiles:
        f=open(os.path.join(path,file),'r')
        for line in f:
            tex=texfind.search(line)
            if tex:
                textures.append(tex.group(1))
    return textures
def image_check_strip(index_fname,ilist1,ilist2=None,size=128):
    """Generate two rows of thumbnails, for easy visual comparison (between the two lists given, or if a single list is given, between low and high resolution)"""
    if ilist2 is None:
        ipairs=[[os.path.join(basedir,'Textures',f),os.path.join(basedir,'Textures.high',f)] for f in ilist1]
    else:
        ipairs=[]
        for f1,f2 in zip(ilist1,ilist2):
            if f1 in low_textures:
                ipairs.append([os.path.join(basedir,'Textures',f1),os.path.join(basedir,'Textures',f2) if f2 in low_textures else os.path.join(basedir,'Textures.high',f2)])
            if f1 in high_textures:
                ipairs.append([os.path.join(basedir,'Textures.high',f1),os.path.join(basedir,'Textures.high',f2) if f2 in high_textures else os.path.join(basedir,'Textures',f2)])
    ilist_f=[f[0] for f in ipairs]+[f[1] for f in ipairs]
    subprocess.call(['montage','-label',"'%f'"]+ilist_f+['-tile','x2','-geometry',str(size)+'x'+str(size)]+[index_fname])
def rsync_rules(flist,include=False,high=None):
    """Output rsync rules to exclude/include the specified textures from high/low/both (high=True/False/None) resolutions"""
    for f in flist:
        if high!=True and f in low_textures:
            print("+" if include else "-",os.path.join('/fgdata/Textures',f))
        if high!=False and f in high_textures:
            print("+" if include else "-",os.path.join('/fgdata/Textures.high',f))
def removal_command(flist,high=None):
    """Return command to delete the specified textures from high/low/both (high=True/False/None) resolutions"""
    a="rm"
    for f in flist:
        if high!=True and f in low_textures:
            a=a+" "+os.path.join('Textures',f)
        if high!=False and f in high_textures:
            a=a+" "+os.path.join('Textures.high',f)
    a=a+"\n"
    return a
def move_command(flist,high=None,comment=False):
    """Return command to move the specified textures to Unused from high/low/both (high=True/False/None) resolutions"""
    dirset_low=set() if high==True else set(os.path.dirname(f) for f in set(flist)&low_textures)
    dirset_high=set() if high==False else set(os.path.dirname(f) for f in set(flist)&high_textures)
    a=""
    for d in dirset_low:
        a=a+("#" if comment else "")+"mv --target-directory="+os.path.join("Textures/Unused",d)+" "+(" ".join(os.path.join("Textures",f) for f in flist if (os.path.dirname(f)==d and f in low_textures)))+"\n"
    for d in dirset_high:
        a=a+("#" if comment else "")+"mv --target-directory="+os.path.join("Textures/Unused",d+".high")+" "+(" ".join(os.path.join("Textures.high",f) for f in flist if (os.path.dirname(f)==d and f in high_textures)))+"\n"
    return a
false_positives=set(['buildings-lightmap.png','buildings.png','Credits','Globe/00README.txt', 'Globe/01READMEocean_depth_1png.txt', 'Globe/world.topo.bathy.200407.3x4096x2048.png','Trees/convert.pl'])#these either aren't textures, or are used where we don't check
used_textures=set(textures_used(basedir+'Materials'))|false_positives
used_textures_noregions=set(textures_used(basedir+'Materials',exclude_dirs=['regions']))|false_positives
used_effectslow=set(textures_used(basedir+'Effects',pattern=r'image.*?>[\\/]?Textures[\\/](\S+?)</.*?image'))|set(textures_used(basedir+'Materials',pattern=r'<building-(?:texture|lightmap).*?>Textures[\\/](\S+?)</building-(?:texture|lightmap)'))#Effects (<image>), and Materials <building-texture>/<building-lightmap>, explicitly includes the Textures/ or Textures.high/
used_effectshigh=set(textures_used(basedir+'Effects',pattern=r'image.*?>[\\/]?Textures.high[\\/](\S+?)</.*?image'))|set(textures_used(basedir+'Materials',pattern=r'<building-(?:texture|lightmap).*?>Textures.high[\\/](\S+?)</building-(?:texture|lightmap)'))
high_tsizes=rfilelist(basedir+'Textures.high')
high_textures=set(high_tsizes.keys())
low_tsizes=rfilelist(basedir+'Textures',exclude_dirs=['Sky','Unused'])#sky textures are used where we don't check
low_textures=set(low_tsizes.keys())
only_high=high_textures-low_textures
used_noreg_onlyhigh=(only_high&used_textures_noregions)|used_effectshigh
used_noreg_onlyhighsize=sum(high_tsizes[t] for t in used_noreg_onlyhigh)
used_noreg_low=(low_textures&used_textures_noregions)|used_effectslow
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
if output_comparison_strips:
    image_check_strip("unused_duplicate.png",unused_duplicate,["Terrain"+f[14:] for f in unused_duplicate])
    image_check_strip("unused_dds.png",unused_dds,[f[:-4]+".png" for f in unused_dds])
    image_check_strip("high_low.png",high_textures&low_textures)
    #image_check_strip("high_low2.png",[f for f in high_textures&low_textures if (f[0:14]=="Terrain.winter" or "_taxiway." in f or "lava" in f or "sand" in f)],size=512)#closer look at the doubtful cases
if output_lists:
    print("\n\nunused-winter same as normal:",sorted(unused_duplicate),"\nsize=",t_size(unused_duplicate),"\n\nunused-dds with matching png:",sorted(unused_dds),"\nsize=",t_size(unused_dds),"\n\nunused-unique:",sorted(unused_other),"\nsize=",t_size(unused_other),"\n\nnot directly used but keep as source:",sorted(needed_as_source),"\nsize=",t_size(needed_as_source),"\n\nunused low, matches high:",sorted(low_unneeded_duplicate),"\nsize=",sum(low_tsizes[f] for f in low_unneeded_duplicate),"\n\nunused low, unique:",sorted(low_unneeded_nondup),"\nsize=",sum(low_tsizes[f] for f in low_unneeded_nondup),"\n\nall non-sky textures size=",sum(high_tsizes.values())+sum(low_tsizes.values()),"used size=",used_defsize,"used no-regions size=",used_noreg_defsize,"\n\nnot found:",sorted(missing),"\n\n.dds only/highest-res:",sorted(sourceless),"\n\n.dds only/highest-res, used:",sorted(sourceless_used))
    #not really meaningful after removing low-res duplicates: ,"\n\nused high-only, not regions:",sorted(used_noreg_onlyhigh),"\nsize=",used_noreg_onlyhighsize,"these+used low (i.e. minimal flightgear-data) size=",used_noreg_onlyhighsize+used_noreg_lowsize
if grep_check:
    unused_f=[os.path.basename(f) for f in unused]
    all_f=[os.path.basename(f) for f in (high_textures|low_textures)]
    print("\n\nPossible use outside main search:")#used to set false_positives
    subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=.git","-e","("+")|(".join(unused)+")","/home/palmer/fs_dev/git/fgdata","/home/palmer/fs_dev/git/flightgear","/home/palmer/fs_dev/git/simgear"])#everywhere using full names
    subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=Textures.high","--exclude-dir=Models","--exclude-dir=Materials","--exclude-dir=Effects","--exclude-dir=.git","-e","("+")|(".join(all_f)+")","/home/palmer/fs_dev/git/fgdata","/home/palmer/fs_dev/git/flightgear","/home/palmer/fs_dev/git/simgear"])#restricted (to avoid false positives from Terrain.winter vs Terrain) using filenames
    subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=Textures.high","--exclude-dir=Models","--exclude-dir=Materials","--exclude-dir=Effects","--exclude-dir=.git","-e",'[."\']dds',"/home/palmer/fs_dev/git/fgdata","/home/palmer/fs_dev/git/flightgear","/home/palmer/fs_dev/git/simgear"])#check for programmatic .png -> .dds swap; none found
    print("\n\nUse of sourceless textures:")
    subprocess.call(["grep","-r","-E","--exclude-dir=Aircraft","--exclude-dir=.git","-e","("+")|(".join(sourceless)+")","/home/palmer/fs_dev/git/fgdata","/home/palmer/fs_dev/git/flightgear","/home/palmer/fs_dev/git/simgear"])
if output_rsync_rules:
    print("\n\nFull flightgear-data:\n")
    rsync_rules(unused)
    rsync_rules(low_unneeded,high=False)
    print("\n\nMinimal flightgear-data:\n")
    rsync_rules(low_textures-used_noreg_low,high=False)
    rsync_rules(high_textures-used_noreg_onlyhigh,high=True)
if output_removal_commands:
    r_script=open('delete_unused_textures.sh','w')
    r_script.write("cd "+basedir+"\n")
    r_script.write("#Unused duplicates\n")
    r_script.write(removal_command(unused_duplicate))
    r_script.write("#Unused .dds versions\n")
    r_script.write(removal_command(unused_dds-unused_dds_matchhigh,high=False))
    r_script.write(removal_command(unused_dds-unused_dds_matchlow,high=True))
    r_script.write("#Unused reduced-resolution versions\n")
    r_script.write(removal_command(low_unneeded_duplicate|(unused_other&high_textures&low_textures)-set(lowres_maybe_source),high=False))
    r_script.write("#Unused unique .png (move to Unused)\n")
    r_script.write("\n".join(["mkdir -p Textures/Unused/"+d for d in ['Terrain','Terrain.winter','Trees','Terrain.high','Terrain.winter.high','Trees.high','Runway','Water']])+"\n")
    r_script.write(move_command([f for f in unused_other&high_textures if (f[-4:]!=".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True))
    r_script.write(move_command([f for f in (unused_other-high_textures)|low_unneeded_nondup if (f[-4:]!=".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=False))
    r_script.write("#Unused unique .dds\n")
    r_script.write("#It is my opinion that these should go, but if you'd prefer to move them to Unused I won't argue further\n")
    r_script.write(removal_command([f for f in (unused_other&high_textures)|unused_dds_matchlow if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True))
    r_script.write(removal_command([f for f in low_unneeded_nondup|unused_dds_matchhigh if f[-4:]==".dds"],high=False))
    r_script.write(move_command([f for f in (unused_other&high_textures)|unused_dds_matchlow if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=True,comment=True))
    r_script.write(move_command([f for f in (unused_other-high_textures)|low_unneeded_nondup|unused_dds_matchhigh if (f[-4:]==".dds" and f[:5]!="Signs" and f[:6]!="Runway")],high=False,comment=True))
    r_script.close()
    
