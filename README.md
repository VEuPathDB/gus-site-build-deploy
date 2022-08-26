# GUS Website Build and Deployment Scripts

This repo houses a set of scripts to ease the packaging and deployment of GUS-based websites.  The goal is to separate the build/packaging step from the deployment step.  Doing so will allow us to, e.g. build a single ApiCommon cohort artifact for deployment to all component integrate sites and possibly use the same artifact for deployment to QA sites or even production.

## Step 1: Building Website Packages

To build, there are two models: "managed" SCM and "manual" SCM.

### Option A: Managed SCM

#### Choose a cohort and branch and build the source code with a dev build config

Note all proj
```
> pwd
/home/rdoherty
> git clone git@github.com:VEuPathDB/gus-site-build-deploy.git
> mkdir my_build
> ./gus-site-build-deploy/bin/veupath-package-website.sh

USAGE: veupath-package-website.sh <working_dir> <tsrcGroup> <gitBranch> <webappPropFile>

> ./gus-site-build-deploy/bin/veupath-package-website.sh my_build apiSite build-cleanup ./gus-site-build-deploy/config/config/webapp.prop.dev

... builds apiSite projects and creates a packaged site artifact (timestamped tar.gz file in my_build/) ... 

> ls -1 my_build
apiSite_build-cleanup_1651953593
apiSite_build-cleanup_1651953593.tar.gz
project_home
```

### Step 2: Unpack the site in a /var/www site directory and configure it
```
> pwd
/home/rdoherty
> ls /var/www/rdoherty.plasmodb.org
# empty directory!
> ./gus-site-build-deploy/bin/veupath-unpack-and-configure.sh 

USAGE: veupath-unpack-and-configure.sh <targz_file> <abs_site_dir> <conifer_site_vars.yml>

> ./gus-site-build-deploy/bin/veupath-unpack-and-configure.sh my_build/apiSite_build-cleanup_1651953593.tar /var/www/rdoherty.plasmodb.org ~/myDevPlasmoConiferSiteVars.yml
```

### Step 3: Deploy webapp to Tomcat, clear WDK cache, etc.
```
> cd /var/www/rdoherty.plasmodb.org
> export GUS_HOME="$(pwd)/gus_home"
> export PATH=$GUS_HOME/bin:$PATH
> instance_manager manage PlasmoDB deploy $GUS_HOME/config/plasmo.rdoherty.xml
> wdkCache -model PlasmoDB -recreate
```
