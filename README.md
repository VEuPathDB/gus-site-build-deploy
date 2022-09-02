# GUS Website Build and Deployment Scripts

This repo houses a pair of scripts to ease and demonstrate the packaging of GUS-based websites and deployment of sites via those packages.  The goal is to separate the build/packaging step from the configuration/deployment step.  Doing so will allow us to, e.g. build a single ApiCommon cohort artifact for deployment to all component integrate sites and possibly use the same successfully built artifact for deployment to QA sites or even production.

## Ingredients

The following pieces are needed for a successful two-part build and deploy sequence:

1. The two bash scripts (or similar) and webapp.prop file in this repo
2. A project storage directory where one or more cohorts of project local checkouts will live (legacy convention would be to name this directory `project_home`)
3. One or more build directories where a cohort will be built and packaged
4. An existing website root directory (e.g. /var/www/qa.plasmodb.org) for each deployment
5. A conifer_site_vars.yml file to configure each deployment

The following example directory structure enables the packaging and deployment of all four website cohorts using the same source code.  It will be used in the instructions below; however, it is only a suggestion.  Other setups will work.

```
.
├── gus-site-build-deploy/ (local checkout of this repo)
│   ├── bin/
│   │   ├── veupath-package-website.sh
│   │   └── veupath-unpack-and-configure.sh
│   ├── config/
│   │   └── webapp.prop
│   ├── LICENSE
│   └── README.md
├── project_home/
│       └── <github_projects>
├── build/
│   ├── api/
│   ├── clinepi/
│   ├── mbio/
│   └── ortho/
├── site_vars/
│   ├── conifer_site_vars.yml.clinepi
│   ├── conifer_site_vars.yml.crypto
│   ├── conifer_site_vars.yml.microbiome
│   ├── conifer_site_vars.yml.ortho
│   ├── conifer_site_vars.yml.plasmo
│   └── <other_conifer_site_vars_files>
```

To create this directory layout:
1. `mkdir -p build/api build/clinepi build/mbio build/ortho project_home site_vars`
2. `git clone git@github.com:VEuPathDB/gus-site-build-deploy.git`
3. Populate site_vars with one or more conifer_site_vars.yml files containing site configuration

## Step 1: Building Website Packages

Decide which cohort you want to build first and check out the files required by that cohort.  In development, you may want to build multiple cohorts from the same source code.  This is supported by using the `websiteRelease` tsrc group.
```
> cd project_home
> tsrc init git@github.com:VEuPathDB/tsrc.git --group websiteRelease
> cd ..
```

This example will build the ApiCommon cohort.  You must learn the root project for the cohort; these are provided in the package script's usage:
```
> ./gus-site-build-deploy/bin/veupath-package-website.sh

USAGE: veupath-package-website.sh <project_home> <working_dir> <rootProject> <webappPropFile>

   Allowed rootProject values: ApiCommonPresenters, OrthoMCLWebsite, ClinEpiPresenters, MicrobiomePresenters
```

Run the package script, specifying the cohort's root project and build sub-directory, project_home, and the standard webapp.prop
```
> ./gus-site-build-deploy/bin/veupath-package-website.sh \
      project_home \
      build/api \
      ApiCommonPresenters \
      gus-site-build-deploy/config/webapp.prop
```

This will build a website package (tar.gz) for the ApiCommon cohort.  The unpackaged website directory is left behind to help debug build problems.  A timestamp is applied to differentiate builds (TBD: there may be a better naming model).  Once complete, something similar to the following should be present:
```
> ls -F1 ./build/api
ApiCommonPresenters_1662091792/
ApiCommonPresenters_1662091792.tar.gz
```

## Step 2: Unpack the site in a /var/www site directory and configure it

Once a site package has been created (Step 1), it can be unpacked and configured.  A second script handles this step; once run, the site is ready to be deployed to Tomcat.  It has the following usage:
```
> ./gus-site-build-deploy/bin/veupath-unpack-and-configure.sh 

USAGE: veupath-unpack-and-configure.sh <targz_file> <absolute_site_dir> <conifer_site_vars.yml>

   Notes: 1. absolute_site_dir will be emptied at the beginning of this script
          2. conifer_site_vars.yml need not be named so; it will be correctly renamed during configuration
```

Note the notes!  To unpack and configure the site artifact we built above to a development Plasmo site, run e.g.:
```
> ./gus-site-build-deploy/bin/veupath-unpack-and-configure.sh \
      build/api/ApiCommonPresenters_1662091792.tar.gz \
      /var/www/rdoherty.plasmodb.org \
      site_vars/conifer_site_vars.yml.plasmo
```

## Step 3: Deploy webapp to Tomcat, clear WDK cache, etc.

Step 2 above does not perform all the functions of rebuilder (which also refreshes SCM by default).  To complete the deployment of the newly deployed and configured site, the following (hopefully familiar) steps must also be taken.
```
> cd /var/www/rdoherty.plasmodb.org
> export GUS_HOME="$(pwd)/gus_home"
> export PATH=$GUS_HOME/bin:$PATH
> instance_manager manage PlasmoDB deploy $GUS_HOME/config/plasmo.rdoherty.xml
> wdkCache -model PlasmoDB -recreate
```
