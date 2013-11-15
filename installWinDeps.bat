REM ExternalProject can't cleanly extract a zip into an existing directory
REM Instead we extract to a subdir, and then move the directories we want
REM using this bat file.

echo %CD%
IF EXIST winDeps/3rdParty (
    md 3rdParty
    xcopy /Y /E winDeps/3rdParty 3rdParty
    echo "Done copying Windows deps"
) ELSE (
    IF EXIST winDeps/3rdParty.x64 (
        md 3rdParty.x64
        xcopy /Y /E winDeps/3rdParty.x64 3rdParty.x64
        echo "Done copying Windows deps"
    ) ELSE (
        echo "Error: Windows deps not found"
        exit -1
    )
)
