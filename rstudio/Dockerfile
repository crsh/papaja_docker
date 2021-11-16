# Select base image
ARG R_RELEASE="4.1.2"
ARG BASE_NAME="papaja"

FROM rocker/rstudio:${R_RELEASE} AS papaja

# System libraries
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libgsl0-dev \
    libnlopt-dev \
    libxt6 \
    ssh \
    fonts-firacode

# TeX Live
ARG TEXLIVE_VERSION=2021

RUN if $TEXLIVE_VERSION == date +"%Y"; then \
        CTAN_REPO=http://mirror.ctan.org/systems/texlive/tlnet; \
    else \
        CTAN_REPO=ftp://tug.org/historic/systems/texlive/$TEXLIVE_VERSION/tlnet-final; \
    fi

ENV CTAN_REPO=$CTAN_REPO
RUN /rocker_scripts/install_texlive.sh
ENV PATH=$PATH:/usr/local/texlive/bin/x86_64-linux

RUN tlmgr install \
    apa6 apa7 booktabs caption csquotes \
    endfloat environ etoolbox fancyhdr \
    fancyvrb framed lineno microtype mptopdf \
    ms parskip pgf sttools threeparttable \
    threeparttablex trimspaces txfonts upquote \
    url was xcolor \
    geometry amsmath kvoptions kvsetkeys kvdefinekeys ltxcmds zapfding \
    auxhook infwarerr multirow babel-english stringenc uniquecounter  \
    epstopdf-pkg grfext bigintcalc bitset etexcmds gettitlestring \
    hycolor hyperref intcalc letltxmacro pdfescape refcount rerunfilecheck \
    latexdiff ulem oberdiek

# Setup R packages
ARG NCPUS=1
RUN install2.r --error \
    --skipinstalled \
    --ncpus $NCPUS \
    tinytex \
    remotes \
    markdown \
    mime

## Latest papaja development version
ARG PAPAJA_VERSION="@devel"
RUN Rscript -e "remotes::install_github('crsh/papaja$PAPAJA_VERSION', dependencies = c('Depends', 'Imports'), Ncpus = $NCPUS, upgrade = FALSE, build = TRUE)"


FROM ${BASE_NAME} as project

# Install packages specified in DESCRIPTION
COPY DESCRIPTION* /home/rstudio/
WORKDIR /home/rstudio/

RUN if test -f DESCRIPTION ; then \
        install2.r --error \
        --skipinstalled \
        $(Rscript -e "pkg <- remotes:::load_pkg_description('.'); repos <- c('https://cloud.r-project.org', remotes:::parse_additional_repositories(pkg)); deps <- remotes:::local_package_deps(pkgdir = '.', dependencies = NA); write(paste0(deps[!deps %in% c('papaja')], collapse = ' '), stdout())"); \
    fi

RUN rm -f DESCRIPTION
RUN rm -rf /tmp/downloaded_packages
RUN mkdir -p .config/rstudio
