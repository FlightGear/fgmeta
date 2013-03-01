

REM ExternalProject can't cleanly extract a zip into an existing directory
REM Instead we extract to a subdir, and then move the directories we want
REM using this bat file.

echo %CD%

xcopy /Y /E winDeps .

echo "Done copying Windows deps"
