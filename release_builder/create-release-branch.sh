#!/bin/bash

THIS_RELEASE="2017.2"
NEXT_RELEASE="2017.3"
SUBMODULES="simgear flightgear fgdata getstart"

#:<< 'COMMENT_END'
git checkout next
git pull --rebase

$(dirname $0)/create-release-branch-for.sh "$THIS_RELEASE" "$NEXT_RELEASE" $SUBMODULES .

# use release branch for submodules
git checkout release/${THIS_RELEASE}
for f in $SUBMODULES; do
  git config -f .gitmodules submodule.${f}.branch release/${THIS_RELEASE}
done
git add .gitmodules && echo "set correct release-branch for submodules" | git commit --file=-

# track submodule changes
git checkout next
git add $SUBMODULES && echo "track submodule changes for release" | git commit --file=-
#COMMENT_END

echo "Check this and submodules $SUBMODULES - hit <enter> to push or <ctrl-c> to cancel"
read something

for f in $SUBMODULES .; do
  pushd "$f"
    echo "Pushing $f"
    git checkout release/${THIS_RELEASE} && git push origin release/${THIS_RELEASE} && git push origin version/${THIS_RELEASE}.1 && git push origin version/${NEXT_RELEASE}.0 && git checkout next && git push
  popd
done

#this needs ~/.ssh/config to contain this
#HOST sf svn.code.sf.net
#        HOSTNAME svn.code.sf.net
#        IdentityFile ~/.ssh/your_sf_keyfile
#        IdentitiesOnly yes
#        User user_sf_username

svn copy svn+ssh://svn.code.sf.net/p/flightgear/fgaddon/trunk \
         svn+ssh://svn.code.sf.net/p/flightgear/fgaddon/branches/release-${THIS_RELEASE} \
         -m "branching for release ${THIS_RELEASE}"
