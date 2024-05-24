#!/bin/bash
#########################################################################
###
### This script will build a site of the chosen cohort and
### package/compress it into a tar.gz artifact.
###
### The resulting artifact can be unpacked in a site directory and
### then configured and deployed without the need for a project_home.
###
#########################################################################

# check args
if [ "$#" != "4" ] && [ "$#" != "5" ]; then
  >&2 echo
  >&2 echo "USAGE: $(basename $0) <project_home> <working_dir> <rootProject> <webappPropFile> [<outputName>]"
  >&2 echo
  >&2 echo "   Allowed rootProject values: ApiCommonPresenters, OrthoMCLWebsite, ClinEpiPresenters, MicrobiomePresenters"
  >&2 echo
  exit 1
fi

# make sure all input locations exist
if ! [ -e $1 ]; then >&2 echo "ERROR: $1 does not exist"; exit 2; fi
if ! [ -e $2 ]; then >&2 echo "ERROR: $2 does not exist"; exit 2; fi
if ! [ -e $4 ]; then >&2 echo "ERROR: $4 does not exist"; exit 2; fi

# name args
projectHomeArg=$1
workingDirArg=$2
rootProject=$3
webappPropArg=$4
outputName=$5

# Define the supported root projects
allowedRootProjects=( ApiCommonPresenters OrthoMCLWebsite ClinEpiPresenters MicrobiomePresenters )

# search supported projects for the one submitted
for allowedRootProject in ${allowedRootProjects[@]}; do
  if [ "$rootProject" == "$allowedRootProject" ]; then
    validRootProject="true"
  fi
done

# error if invalid root project
if [ "$validRootProject" == "" ]; then
  >&2 echo "ERROR: $rootProject is not supported"
  exit 1
fi

# local vars
projectHome=$(realpath $projectHomeArg)
workingDir=$(realpath $workingDirArg)
webappPropFile=$(realpath $webappPropArg)

# set build ID
if [ "$outputName" == "" ]; then
  timestamp=$(date --utc '+%s')
  buildId="${rootProject}_${timestamp}"
else
  buildId="$outputName"
fi

siteDir=$workingDir/$buildId

# env vars for the build
export GUS_HOME=$workingDir/$buildId/gus_home
export PROJECT_HOME=$projectHome
export PATH=$GUS_HOME/bin:$PROJECT_HOME/install/bin:$PATH

# use a private maven repo to ensure build independence
export M2_REPO=$PROJECT_HOME/.mavenRepo

# visit project home
cd $PROJECT_HOME

# announce
echo "Will build with the following config:"
echo "  GUS_HOME = $GUS_HOME"
echo "  PROJECT_HOME = $PROJECT_HOME"
echo "  webappPropFile = $webappPropFile"
echo "  buildId = $buildId"

# conditionally build and package
echo "Building website with root project $rootProject using prop file $webappPropFile" \
  && bldw $rootProject $webappPropFile -skipBinFileLocationMacros \
  && cd $siteDir \
  && echo "Packing built site into $buildId.tar" \
  && tar cf ../$buildId.tar * \
  && cd .. \
  && echo "Gzipping tar file" \
  && gzip $buildId.tar \
  && echo "Done. Packaged site written to $(realpath $buildId.tar)"
