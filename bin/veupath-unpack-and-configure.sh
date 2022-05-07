#!/bin/bash
#########################################################################
###
### This script will copy, uncompress, and unpack a tar.gz site bundle
### into a designated site directory and configure it using the basename
### of the target directory (i.e. domain name of the site).
###
#########################################################################

# check args
if [ "$#" != "3" ]; then
  >&2 echo
  >&2 echo "USAGE: $(basename $0) <targz_file> <abs_site_dir> <conifer_site_vars.yml>"
  >&2 echo
  exit 1
fi

# make sure all input locations exist
function presentOrDie {
  if ! [ -e $1 ]; then
    >&2 echo "ERROR: $1 does not exist"
    exit 2
  fi
  echo $1
}

targzFile=$(presentOrDie $1)
siteDir=$(presentOrDie $2)
siteConfigFile=$(presentOrDie $3)

gzFilename=$(basename $targzFile)
tarFilename=$(echo $gzFilename | sed 's/\.gz//' -)
domain=$(basename $siteDir)

echo "Copying $targzFile to $siteDir"
cp $targzFile $siteDir

echo "Generated values: $domain $gzFilename $tarFilename"

cd $siteDir
gunzip $gzFilename
tar xvf $tarFilename
rm $tarFilename

cp $siteConfigFile $siteDir/etc/conifer_site_vars.yml

export GUS_HOME=$siteDir/gus_home
export PROJECT_HOME=$siteDir/project_home
export PATH=$GUS_HOME/bin:$PATH

conifer configure $domain

#TODO: fill templates in cgi-bin
