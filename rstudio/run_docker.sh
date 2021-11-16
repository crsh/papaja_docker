#!/bin/sh

# BASE_NAME is the name used for the base image that can be reused across
# projects to save disk space and get up and running more quickly
#
# PROJECT_NAME is the name used for the image of the current project (including
# project-specific R packages etc.)
#
# Names must be lowercase.

BASE_NAME="papaja"
PROJECT_NAME="papajaworkshop"

# Look up available R_RELEASE's at
# https://github.com/rocker-org/rocker-versioned2/tree/master/stacks
#
# PAPAJA_VERSION's are appended to the repostiory URL;
# see ?remotes::install_github
#
# For valid RSTUDIO_VERSION's refer to
# https://www.rstudio.com/products/rstudio/release-notes/
#
# Any year starting from 2000 is a valid TEXLIVE_VERSION

R_RELEASE="4.1.2"
RSTUDIO_VERSION="2021.09.0+351"
TEXLIVE_VERSION="2021"
PAPAJA_VERSION="@devel" # Eventually we should only accept releases here

# NCPUS controls the number of cores to use to install R packages in parallel

NCPUS=1


# ------------------------------------------------------------------------------

TAG="$R_RELEASE-$(echo $PAPAJA_VERSION | grep -o "\w*$")-$(echo $RSTUDIO_VERSION | grep -o "^[0-9]*\.[0-9][0-9]")-$TEXLIVE_VERSION"
BASE_NAME="papaja:$TAG"
PROJECT_NAME="$PROJECT_NAME:$TAG"

# Add to both builds to specify a MRAN snapshot
# 
#   --build-arg BUILD_DATE=<DATE>

docker build \
    --build-arg R_RELEASE=$R_RELEASE \
    --build-arg RSTUDIO_VERSION=$RSTUDIO_VERSION \
    --build-arg TEXLIVE_VERSION=$TEXLIVE_VERSION \
    --build-arg PAPAJA_VERSION=$PAPAJA_VERSION \
    --build-arg NCPUS=$NCPUS \
    --target papaja \
    -t $BASE_NAME .

docker build \
    --build-arg BASE_NAME=$BASE_NAME \
    --build-arg PROJECT_NAME=$PROJECT_NAME \
    --build-arg NCPUS=$NCPUS \
    --target project \
    -t $PROJECT_NAME .

# Add to work seamlessly with git inside the container
#
# Share global .gitconfig with container
#    --mount type=bind,src="/$HOME/.gitconfig",dst=/home/rstudio/.gitconfig,readonly \
#
# Share SSH credentials with container
#    --mount type=bind,src="/$HOME/.ssh",dst=/home/rstudio/.ssh,readonly \

if test ! -f DESCRIPTION ; then \
    Rscript -e "usethis::use_description(fields = list(Remotes = c('github::crsh/papaja@devel')), check_name = FALSE, roxygen = FALSE)"
fi

if test ! -f CITATION ; then \
    Rscript -e "usethis::use_template('citation-template.R', 'CITATION', data = usethis:::package_data(), open = TRUE)"
fi

Rscript -e "cffr::cff_write()"

docker run -d \
    -p 8787:8787 \
    -e DISABLE_AUTH=TRUE \
    -e ROOT=TRUE \
    --mount type=bind,src="/$PWD",dst=/home/rstudio \
    --mount type=bind,src="/$(Rscript -e 'cat(path.expand(usethis:::rstudio_config_path()))')",dst=/home/rstudio/.config/rstudio \
    --name $(echo $PROJECT_NAME | grep -o "^[a-zA-Z0-9]*") \
    --rm \
    $PROJECT_NAME

sleep 1

git web--browse http://localhost:8787
