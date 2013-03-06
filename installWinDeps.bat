

REM ExternalProject can't cleanly extract a zip into an existing directory
REM Instead we extract to a subdir, and then move the directories we want
REM using this bat file.

echo %CD%

md 3rdParty
xcopy /Y /E winDeps/3rdParty 3rdParty

echo "Done copying Windows deps"
