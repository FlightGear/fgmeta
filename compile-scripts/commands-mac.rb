#!/usr/bin/ruby

require 'fileutils'
require 'optparse'
include FileUtils

baseDir = Dir.pwd
gitArgs = ""
qtPath = ""

doPull = false
doCMake = false
doInit = false
doClean = false
doPackage = false

cmakePlatformArgs = "-G Xcode"
cmakeCommonArgs = "-DCMAKE_INSTALL_PREFIX=#{baseDir}/dist"
cmakeSGArgs = "-DSIMGEAR_SHARED=1"
cmakeFGArgs = "-DSIMGEAR_SHARED=1"
sfUser = "jmturner"

OptionParser.new do |opts|
  opts.banner = "Usage: commands.rb [options]"
  opts.on("", "--init", "Setup empty") do |v|
    doInit = v
  end

  opts.on("-p", "--[no-]pull", "Pull from Git") do |v|
    doPull = v
  end
  opts.on("-c", "--cmake", "Run Cmake") do |v|
    doCMake = v
  end
  opts.on("", "--clean", "Clean build dirs") do |v|
    doClean = v
  end
  opts.on("-r", "--rebase", "Rebase when pulling") do |v|
    gitArgs += "--rebase"
  end

  opts.on("", "--qt=QTPATH", "Set Qt path when running cmake") do |v|
    qtPath = v
  end
end.parse!(ARGV)

def cloneEverything()
  puts "Initialising"
  if File.exist?("#{Dir.pwd}/simgear") or File.exist?("#{Dir.pwd}/flightgear")
    puts "Checkout already exists"
    return
  end

  `git clone ssh://#{sfUser}@git.code.sf.net/p/flightgear/simgear simgear`
  `git clone ssh://#{sfUser}@git.code.sf.net/p/flightgear/flightgear flightgear`
  `git clone git@github.com:zakalawe/osg.git osg`
end

def createDirs()
  `mkdir -p sgbuild`
  `mkdir -p fgbuild`
  `mkdir -p osg_fg_build`
end

# path is needed for Cmake & running macdeployqt
if qtPath != ""
  ENV['PATH'] = "#{ENV['PATH']}:#{qtPath}/bin"
end

if doClean
  puts "Cleaning build dirs"
  `rm -r sgbuild`
  `rm -r fgbuild`
  `rm -r osg_fg_build`
end

if doInit
  puts "Doing init"
    cloneEverything()
end

if doPull
  puts "Pulling from Git"
  dataPull = Thread.new do
    puts "Syncing FGData"
    Dir.chdir "#{baseDir}/fgdata"
    `git pull #{gitArgs}`
  end

  Dir.chdir "#{baseDir}/simgear"
  `git pull #{gitArgs}`

  Dir.chdir "#{baseDir}/flightgear"
  `git pull #{gitArgs}`
end

createDirs()

Dir.chdir "#{baseDir}/osg_fg_build"
if doCMake or !File.exist?("#{Dir.pwd}/Makefile")
  `cmake ../osg #{cmakeCommonArgs}`
end

puts "Building OpenSceneGraph"
`make -j4`
`make install`

Dir.chdir "#{baseDir}/sgbuild"

if doCMake or !File.exist?("#{Dir.pwd}/SimGear.xcodeproj")
  `cmake ../simgear #{cmakePlatformArgs} #{cmakeCommonArgs} #{cmakeSGArgs}`
end

puts "Building SimGear Debug"
`xcodebuild -target install -configuration Debug`

puts "Building SimGear Release"
`xcodebuild -target install -configuration Release`

Dir.chdir "#{baseDir}/fgbuild"

if doCMake or !File.exist?("#{Dir.pwd}/FlightGear.xcodeproj")
  if qtPath != ""
    cmakeFGArgs = '-DENABLE_QT=1'
  end
  `cmake ../flightgear #{cmakePlatformArgs} #{cmakeCommonArgs} #{cmakeFGArgs}`
end

puts "Building FlightGear Debug"
`xcodebuild -target fgfs -configuration Debug`

puts "Building FlightGear Release"
`xcodebuild -target fgfs -configuration Release`

puts "All done."
