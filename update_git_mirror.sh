#!/bin/bash

mirror_dirs='fgdata fgmeta flightgear simgear getstart windows-3rd-party fgrun'

pushd /var/lib/git

for dir in $mirror_dirs
do
	repo_name=$dir.git
	if [ ! -d "$repo_name" ]; then
		echo "Doing initial clone"
		git clone --mirror git://git.code.sf.net/p/flightgear/$dir
	fi

	pushd $repo_name
	echo "Updating in $PWD"
	git remote update
	popd
done

popd

