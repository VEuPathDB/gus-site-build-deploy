#!/bin/bash
#########################################################################
###
### This script will check out a source tree for a website cohort,
### build the site, and package/compress it into a tar.gz artifact.
###
### The resulting artifact can be unpacked in a site directory and
### then configured and deployed without the need for a project_home.
###
#########################################################################

# check args
if [ "$#" != "4" ]; then
  >&2 echo
  >&2 echo "USAGE: $(basename $0) <working_dir> <tsrcGroup> <gitBranch> <webappPropFile>"
  >&2 echo
  exit 1
fi

# make sure all input locations exist
if ! [ -e $1 ]; then >&2 echo "ERROR: $1 does not exist"; exit 2; fi
if ! [ -e $4 ]; then >&2 echo "ERROR: $4 does not exist"; exit 2; fi

# name args
workingDirArg=$1
groupParam=$2
branch=$3
webappPropArg=$4

# Define the supported groups and assign a root build project to each
allowedGroups=( "apiSite:ApiCommonPresenters"
                "orthoSiteOrthoMCLWebsite"
                "clinEpiSite:ClinEpiPresenters"
                "microbiomeSite:MicrobiomePresenters" )

# search supported groups for the one submitted
for allowedGroup in ${allowedGroups[@]}; do
  map=( $(echo $allowedGroup | sed 's/:/ /g') )
  if [ "$groupParam" == "${map[0]}" ]; then
    group=${map[0]}
    rootProject=${map[1]}
  fi
done

# make sure tsrc group is valid
if [ "$group" == "" ]; then
  >&2 echo "ERROR: $groupParam is not supported"
  exit 1
fi

# local vars
workingDir=$(realpath $workingDirArg)
webappPropFile=$(realpath $webappPropArg)
timestamp=$(date --utc '+%s')
buildId="${group}_${branch}_${timestamp}"
siteDir=$workingDir/$buildId

# env vars for the build
export GUS_HOME=$workingDir/$buildId/gus_home
export PROJECT_HOME=$workingDir/project_home
export PATH=$GUS_HOME/bin:$PROJECT_HOME/install/bin:$PATH

# use a private maven repo to ensure build independence
export M2_REPO=$PROJECT_HOME/.mavenRepo

# create and visit project home
mkdir -p $PROJECT_HOME
cd $PROJECT_HOME

# announce
echo "Will build with the following config:"
echo "  GUS_HOME = $GUS_HOME"
echo "  PROJECT_HOME = $PROJECT_HOME"
echo "  webappPropFile = $webappPropFile"

# conditionally clone repos, build, and package
echo "Cloning projects in group $group"
tsrc init git@github.com:VEuPathDB/tsrc.git --group $group \
  && echo "Switching to branch $branch" \
  && tsrc foreach -- git checkout $branch \
  && echo "Building website with root project $rootProject using prop file $webappPropFile" \
  && bldw $rootProject $webappPropFile \
  && cd $siteDir \
  && echo "Packing built site into $buildId.tar" \
  && tar cf ../$buildId.tar * \
  && cd .. \
  && echo "Gzipping tar file" \
  && gzip $buildId.tar \
  && echo "Done. Packaged site written to $(realpath $buildId.tar)"
