#!/bin/bash
#########################################################################
###
### This script will copy, uncompress, and unpack a tar.gz site bundle
### into a designated site directory and configure it using the basename
### of the target directory (i.e. domain name of the site).
###
### Note: it will completely clear out the target directory, so make
###       sure nothing important is in there!
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
if ! [ -e $1 ]; then >&2 echo "ERROR: $1 does not exist"; exit 2; fi
if ! [ -e $2 ]; then >&2 echo "ERROR: $2 does not exist"; exit 2; fi
if ! [ -e $3 ]; then >&2 echo "ERROR: $3 does not exist"; exit 2; fi

# name args
targzFile=$1
siteDir=$2
siteConfigFile=$3

# local vars
gzFilename=$(basename $targzFile)
tarFilename=$(echo $gzFilename | sed 's/\.gz//' -)
domain=$(basename $siteDir)

echo "Cleaning out $siteDir"
rm -rf $siteDir/*

echo "Copying $targzFile to $siteDir"
cp $targzFile $siteDir

echo "Generated values: $domain $gzFilename $tarFilename"

cd $siteDir

echo "Unzipping tar file..."
gunzip $gzFilename

echo "Extracting site..."
tar xf $tarFilename
rm $tarFilename

echo "Copying conifer config..."
cp $siteConfigFile $siteDir/etc/conifer_site_vars.yml

echo "Configuring environment..."
export GUS_HOME=$siteDir/gus_home
export PROJECT_HOME=$siteDir/project_home
export PATH=$GUS_HOME/bin:$PATH

echo "Configuring site with conifer..."
conifer configure $domain

##########################################################################
###  Hacks around normal procedures; can maybe be avoided in the future
##########################################################################

# 1. fill templates macros in cgi-bin perl scripts

# FIXME: there may be a more elegant solution to this using apache env vars
echo "Populating location macros in cgi-bin..."
cd $siteDir/cgi-bin
for file in `ls`; do
  if [ -f $file ]; then
    sed "s|\@cgilibTargetDir\@|$siteDir/cgi-lib|g" $file > ${file}.mod && mv ${file}.mod $file
    sed "s|\@targetDir\@|$GUS_HOME|g" $file > ${file}.mod && mv ${file}.mod $file
  fi
done

# 2. open certain jbrowse track directories for writing

# FIXME: the webapp writes cache files here; should probably find a better location outside gus_home
if [ -e $GUS_HOME/lib/jbrowse/auto_generated ]; then
  echo "Opening directories to store JBrowse caches..."
  find $GUS_HOME/lib/jbrowse/auto_generated/* | xargs chmod 777
  find $GUS_HOME/lib/jbrowse/auto_generated/*/aa | xargs chmod 777
fi

echo "Done."
