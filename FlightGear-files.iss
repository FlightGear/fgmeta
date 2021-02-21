[Files]
; 32 bits install
Source: "{#InstallDir32}\bin\*.*"; DestDir: "{app}\bin"; Excludes: "{#ExcludedBinaries}"; Flags: ignoreversion recursesubdirs; Check: not Is64BitInstallMode
Source: "{#InstallCompositor32}\bin\fgfs.exe"; DestDir: "{app}\bin"; DestName: "fgfs-compositor.exe"; Excludes: "{#ExcludedBinaries}"; Flags: ignoreversion recursesubdirs; Check: not Is64BitInstallMode

Source: "{#ThirdPartyDir}\3rdParty\bin\zlib.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\OpenAL32.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\libpng.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\libcurl.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\libintl-8.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\sentry.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\crashpad_handler.exe"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\dbus-1-3.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\event_core.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty\bin\liblzma.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode

; 64 bits install
Source: "{#InstallDir64}\bin\*.*"; DestDir: "{app}\bin"; Excludes: "{#ExcludedBinaries}"; Flags: ignoreversion recursesubdirs; Check: Is64BitInstallMode
Source: "{#InstallCompositor64}\bin\fgfs.exe"; DestDir: "{app}\bin"; DestName: "fgfs-compositor.exe"; Excludes: "{#ExcludedBinaries}"; Flags: ignoreversion recursesubdirs; Check: Is64BitInstallMode

Source: "{#ThirdPartyDir}\3rdParty.x64\bin\zlib.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\OpenAL32.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\libpng.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\libcurl.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\libintl-8.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\sentry.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\crashpad_handler.exe"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\dbus-1-3.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\event_core.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#ThirdPartyDir}\3rdParty.x64\bin\liblzma.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode

; Include the base package
#if IncludeData == "TRUE"
Source: "{#FgHarnessPath}\fgdata\*.*"; DestDir: "{app}\data"; Excludes: "{#FGDataExcludes}"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist
#endif

; Web installer for the base package
#if IncludeWeb == "TRUE"
; bzip2
Source: "{#DecompressDir}\\bunzip2.exe"; Flags: dontcopy
Source: "{#DecompressDir}\\bzip2.dll"; Flags: dontcopy
; tar
Source: "{#DecompressDir}\\tar.exe"; Flags: dontcopy
Source: "{#DecompressDir}\\libiconv-2.dll"; Flags: dontcopy
Source: "{#DecompressDir}\\libintl-2.dll"; Flags: dontcopy
; txz
Source: "{#DecompressDir}\\xzdec.exe"; Flags: dontcopy
Source: "{#DecompressDir}\\liblzma.dll"; Flags: dontcopy
; full code
Source: "{tmp}\\fgdata-extracted\\fgdata\\*.*"; DestDir: "{app}\data"; Flags: external recursesubdirs
#endif

; 32 bits install
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osg.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgDB.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgGA.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgParticle.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgText.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgUtil.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgViewer.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgSim.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\osg{#OSGSoNumber}-osgFX.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode
Source: "{#OSGInstallDir}\bin\ot{#OTSoNumber}-OpenThreads.dll"; DestDir: "{app}\bin"; Check: not Is64BitInstallMode

Source: "{#OSGPluginsDir}\osgdb_ac.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_osg.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_osga.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_3ds.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_mdl.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_jpeg.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_rgb.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_png.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_dds.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_txf.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_tiff.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode
Source: "{#OSGPluginsDir}\osgdb_freetype.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Check: not Is64BitInstallMode

; 64 bits install
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osg.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgDB.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgGA.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgParticle.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgText.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgUtil.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgViewer.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgSim.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgFX.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
Source: "{#OSG64InstallDir}\bin\ot{#OTSoNumber}-OpenThreads.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode

Source: "{#OSG64PluginsDir}\osgdb_ac.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_osg.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_osga.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_3ds.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_mdl.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_jpeg.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_rgb.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_png.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_dds.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_txf.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_tiff.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_freetype.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
