[Files]
; 64 bits install
Source: "{#InstallDir64}\bin\*.*"; DestDir: "{app}\bin"; Excludes: "{#ExcludedBinaries}"; Flags: ignoreversion recursesubdirs; Check: Is64BitInstallMode

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
Source: "{#FgHarnessPath}\fgdata\*.*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist
#endif

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
Source: "{#OSG64InstallDir}\bin\osg{#OSGSoNumber}-osgTerrain.dll"; DestDir: "{app}\bin"; Check: Is64BitInstallMode
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
Source: "{#OSG64PluginsDir}\osgdb_osgterrain.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode

Source: "{#OSG64PluginsDir}\osgdb_serializers_osg.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
Source: "{#OSG64PluginsDir}\osgdb_serializers_osgterrain.dll"; DestDir: "{app}\bin\osgPlugins-{#OSGVersion}"; Flags: skipifsourcedoesntexist; Check: Is64BitInstallMode
