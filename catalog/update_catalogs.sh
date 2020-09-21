#!/bin/bash

# can't rely on $HOME in cron scripts
script_home=/home/fgaddon

# we assume fgmeta is checked out to $script_home/fgmeta

# add the scripts to the path
catalog_dir=$script_home/fgmeta/catalog
local_www_dir=/var/www/uk-mirror/fgaddon
output_dir=$script_home/output
rsync_args="-avz"

# this assumes there is an 'ibiblio' entry setup in $HOME/.ssh/config with the appropriate
# credentials
ibiblio_prefix=ibiblio:/public/mirrors/flightgear/ftp/
alias python=python3

export PATH=$PATH:$catalog_dir
export PYTHONPATH=$script_home/fgmeta/python3-flightgear

echo "Generating trunk catalog"

update-catalog.py --quiet --update $catalog_dir/fgaddon-catalog-ukmirror

# at some point, we can disable updating the 2018 catalog
echo "Generating stable catalog 2018"
update-catalog.py --quiet --update $catalog_dir/stable-2018-catalog

echo "Generating stable catalog 2020"

update-catalog.py --quiet --update $catalog_dir/stable-2020-catalog

#echo "Generating legacy catalog"
#update-catalog.py --no-update $catalog_dir/legacy-catalog

echo "Coping to WWW dir"

rsync -avz $output_dir/Aircraft-trunk $local_www_dir/
rsync -avz $output_dir/Aircraft-2018 $local_www_dir/
rsync -avz $output_dir/Aircraft-2020 $local_www_dir/
#rsync -avz $output_dir/Aircraft $local_www_dir/

# temporarily disabled
#echo "Syncing to Ibiblio"

#rsync $rsync_args $output_dir/Aircraft-trunk $ibiblio_prefix
#rsync $rsync_args $output_dir/Aircraft-2018 $ibiblio_prefix
#rsync $rsync_args $output_dir/Aircraft-2020 $ibiblio_prefix
#rsync $rsync_args $output_dir/Aircraft $ibiblio_prefix

echo "All done"



