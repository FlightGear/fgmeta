#!/usr/bin/ruby

require 'ERB'
require 'fileutils' #I know, no underscore is not ruby-like
include FileUtils

$osgLibs = ['osgFX', 'osgParticle', 'osg', 'osgGA', 'osgText', 'osgUtil', 'osgSim', 'osgViewer', 'osgDB']
$osgPlugins = ['ac', 'osg', 'freetype', 'imageio', 'rgb', 'txf', 'mdl', '3ds']

# from http://drawingablank.me/blog/ruby-boolean-typecasting.html
class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class NilClass
  def to_bool; false; end
end

def runOsgVersion(option)
  env = "export DYLD_LIBRARY_PATH=#{Dir.pwd}/dist/lib"
  bin = Dir.pwd + "/dist/bin/osgversion"
  return `#{env}; #{bin} --#{option}`.chomp
end

osgVersion = runOsgVersion('version-number')
$osgSoVersion=runOsgVersion('so-number')
$openThreadsSoVersion=runOsgVersion('openthreads-soversion-number')

$codeSignIdentity = ENV['FG_CODESIGN_IDENTITY']
puts "Code signing identity is #{$codeSignIdentity}"
puts "osgVersion=#{osgVersion}, so-number=#{$osgSoVersion}"

$isRelease = ENV['FG_IS_RELEASE'].to_bool
puts "Is-release? : ##{$isRelease}"

$prefixDir=Dir.pwd + "/dist"
dmgDir=Dir.pwd + "/image"
srcDir=Dir.pwd + "/flightgear"

puts "Erasing previous image dir"
`rm -rf #{dmgDir}`

bundle=dmgDir + "/FlightGear.app"

# run macdeployt before we rename the bundle, otherwise it
# can't find the bundle executable
puts "Running macdeployqt on the bundle to copy Qt libraries"
`macdeployqt #{$prefixDir}/fgfs.app`

puts "Moving & renaming app bundle"
`mkdir -p #{dmgDir}`
`mv #{$prefixDir}/fgfs.app #{bundle}`

bundle=dmgDir + "/FlightGear.app"
contents=bundle + "/Contents"
macosDir=contents + "/MacOS"
$frameworksDir=contents +"/Frameworks"
resourcesDir=contents+"/Resources"
osgPluginsDir=contents+"/PlugIns/osgPlugins"

# for writing copyright year to Info.plist
t = Time.new
fgCurrentYear = t.year

fgVersion = File.read("#{srcDir}/version").strip
volName="\"FlightGear #{fgVersion}\""

if $isRelease
  dmgPath = "" # no 'lite' build for release candidates
  dmgFullPath = Dir.pwd + "/output/FlightGear-#{fgVersion}.dmg"
else
  dmgPath = Dir.pwd + "/output/FlightGear-#{fgVersion}-nightly.dmg"
  dmgFullPath = Dir.pwd + "/output/FlightGear-#{fgVersion}-nightly-full.dmg"
end

puts "Creating directory structure"
`mkdir -p #{macosDir}`
`mkdir -p #{$frameworksDir}`
`mkdir -p #{resourcesDir}`
`mkdir -p #{osgPluginsDir}`


puts "Copying auxilliary binaries"
bins = ['fgjs', 'fgcom']
bins.each do |b|
  if !File.exist?("#{$prefixDir}/bin/#{b}")
    next
  end

  outPath = "#{macosDir}/#{b}"
  `cp #{$prefixDir}/bin/#{b} #{outPath}`
end

puts "copying libraries"
$osgLibs.each do |l|
  libFile = "lib#{l}.#{$osgSoVersion}.dylib"
  `cp #{$prefixDir}/lib/#{libFile} #{$frameworksDir}`
end

# and not forgetting OpenThreads
libFile = "libOpenThreads.#{$openThreadsSoVersion}.dylib"
`cp #{$prefixDir}/lib/#{libFile} #{$frameworksDir}`

$osgPlugins.each do |p|
  pluginFile = "osgdb_#{p}.dylib"
  `cp #{$prefixDir}/lib/osgPlugins/#{pluginFile} #{osgPluginsDir}`
end

if File.exist?("#{$prefixDir}/bin/fgcom-data")
  puts "Copying FGCom data files"
  `ditto #{$prefixDir}/bin/fgcom-data #{resourcesDir}/fgcom-data`
end

# Info.plist
template = File.read("Info.plist.in")
output = ERB.new(template).result(binding)

File.open("#{contents}/Info.plist", 'w') { |f|
  f.write(output)
}

`cp #{srcDir}/package/mac/FlightGear.icns #{resourcesDir}/FlightGear.icns`
`cp #{srcDir}/COPYING #{dmgDir}`

# move documentation to a public place
`cp fgdata/Docs/FGShortRef.pdf "#{dmgDir}/Quick Reference.pdf"`
`cp fgdata/Docs/getstart.pdf "#{dmgDir}/Getting Started.pdf"`

createArgs = "-format UDBZ -imagekey bzip2-level=9 -quiet -volname #{volName}"


if !$isRelease
  # create the 'lite' DMG without the base files

  # code sign the entire bundle once complete - v2 code-signing
  puts "Signing #{bundle}"
  `codesign --deep -s "#{$codeSignIdentity}" #{bundle}`
  puts "Creating DMG"

  `rm #{dmgPath}`
  `hdiutil create -srcfolder #{dmgDir} #{createArgs} #{dmgPath}`
end

puts "Creating full image with data"

puts "Copying base package files into the image"
`rsync -a fgdata/ #{resourcesDir}/data`

# re-sign the entire bundle
puts "Re-signing full #{bundle}"
`codesign --force --deep -s "#{$codeSignIdentity}" #{bundle}`

`rm #{dmgFullPath}`
`hdiutil create -srcfolder #{dmgDir} #{createArgs} #{dmgFullPath}`
