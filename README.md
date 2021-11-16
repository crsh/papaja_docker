# A Docker workflow to work reproducibly with papaja

<!-- Add logo of the papaja riding the Docker whale -->

This repository provides tools to interactively create dynamic, submission-ready, APA-style mansucripts in R with the R package [`papaja`](https://github.com/crsh/papaja) inside a Docker container.

## Why use a Docker workflow?

Working inside a Docker container, rather than in your local environment, safeguards mid- to long-term computational reproducibility of the manuscript.
Docker containers clearly define—and thereby conserve—the software environment used to write a manuscript and provide the means to conveniently share and recreate the environment.
In doing so, containers prevent [code rot](https://en.wikipedia.org/wiki/Software_rot) (that is, code breaking because of changes to the software environment, such as R package updates) and contribute to the computational reproducibility of the manuscript.
This is particularly important for workflows that involve nontrivial software dependencies,as in the case of `rmarkdown` and `papaja` (e.g., R and all R packages, LaTeX and LaTeX packages, pandoc and pandoc filters; see [Figure 1.1 of the `papaja` manual](http://frederikaust.com/papaja_man/introduction.html#fig:compilation-process-diagram)).
For a brief primer on containers see [the supplementary material](https://psych-transparency-guide.uni-koeln.de/analytic-reproducibility.html#document-hardware-and-software-used-for-analyses) by [Klein et al. (2018)](http://frederikaust.com/papaja_man/references.html#ref-klein_practical_2018).
For a concise hands-on introduction see the [ROpenSci Docker tutorial](https://ropenscilabs.github.io/r-docker-tutorial/); a [more comprehensive introduction](https://docker-curriculum.com/) is available from the Docker project.


## What are my options?

The tools provided here are geared towards working *interactively* with `papaja` inside a Docker container.
There will be two options:

- [X] **RStudio** &nbsp; Use a web browser to work with an instance of RStudio installed inside the container (builds on the `rocker/rstudio` image)
- [ ] **VS Code** &nbsp; Use an existing installation of VS Code and the Containers extension on the host system to work inside a container

<!-- Install a specific version of pandoc instead? -->


## Prerequisites

[Install Docker](https://docs.docker.com/get-docker/) and confirm that Docker is set up correctly the following in the [shell](https://happygitwithr.com/shell.html)

~~~bash
docker run hello-world
~~~

You should see the following output:

~~~txt
Hello from Docker.
This message shows that your installation appears to be working correctly.
...
~~~

Although only strictly necessary for Windows users who intend to use the RStudio option, I recommend [installing Git](https://happygitwithr.com/install-git.html).
Windows users should add Git bash to the Windows context menu (this should be the default).
Without Git installed, replace `git web--browse` in the last line of `run_docker.sh` by `open` (Mac OS or Linux).


## The RStudio container

The container comes, among other things, with the latest version of Debian and user-specified versions of R, RStudio (including `pandoc`), TeX Live, and `papaja` (by default the latest versions are used).

### How to use

1. Place `run_docker.sh` and `Dockerfile` in your project directory
2. Edit `run_docker.sh` and set variables at the top of the script (see below)
3. Execute `run_docker.sh` in the [shell](https://happygitwithr.com/shell.html)

~~~bash
sh run_docker.sh
~~~

Note, Windows users may need to explicitly grant Docker access to the project directory (see `Settings > Resources > File sharing`).

4. Work interactively with RStudio in the browser
5. Stop the container
   - Results not saved to the project directory will be lost
   - Interactively installed packages (e.g., `install.packages()`) will be lost and should be added to `DESCRIPTION`

~~~bash
docker stop <PROJECT_NAME>
~~~


### What `run_docker.sh` does

The script performs the following series of actions

1. Build `papaja` base image named `<BASE_NAME>`
    - This image will be reused across projects as appropriate to save disk space and get started more quickly
2. Build a project-specific image named `<PROJECT_NAME>`
    - Installs R package dependencies (as specified in `DESCRIPTION`) from [MRAN snapshot](https://mran.microsoft.com/documents/rro/reproducibility) (see below)
3. Unless present, create files
    - `DESCRIPTION`
    - `CITATION`
    - `CITATION.cff`
4. Run container
    - Share current shell working directory with container (this should be the project directory)
5. Open a browser window with RStudio
6. When the container is stopped, it is automatically removed


### `run_docker.sh` options

The top section of the script defines several project-specific variables that define the software environment.

| Variable           | Description                                                                                                        |
| -----------------: | :----------------------------------------------------------------------------------------------------------------- |
| `PAPAJA_BASE_NAME` | Base image name (must be lowercase)                                                                          |
| `PROJECT_NAME`     | Project image name (must be lowercase                                                                       |
| `R_RELEASE`        | R version to use.                                                                                                  |
| `RSTUDIO_VERSION`  | RStudio version to use. For available versions see [here](https://www.rstudio.com/products/rstudio/release-notes/). |
| `TEXLIVE_VERSION`  | Year of the TeX Live distribution to use (2000 or later)                                    |
| `PAPAJA_VERSION`   | `papaja` version to use (Git commit, branch, or tag; see `?remotes::install_github`).                              |
| `NCPUS`            | Number of cores used to install R packages.                                                                        | 

### Specify an MRAN snapshot

By default, R packages are installed from the [MRAN snapshot](https://mran.microsoft.com/documents/rro/reproducibility) corresponding to the last day that the specified R version was the most recent release.
A different MRAN snapshot can be specified in the calls to `docker build`:

~~~bash
docker build \
    --build-arg BUILD_DATE=<DATE> \
    ...
~~~

### Install a specific version of an R package

To install a specific version of an R package, adapt the following as necessary and append it to the `Dockerfile`:

~~~Dockerfile
RUN Rscript -e "remotes::install_version('rlang', '0.4.7', repos = 'http://cran.us.r-project.org', upgrade = FALSE, Ncpus = $NCPUS)"
~~~

## Use Git inside the container

The containers provided here come with Git (and SSH) installed.
To seamlessly use Git inside the container, grant the container access to `.gitconfig` by adding the following to the `docker run` call:

~~~bash
docker run -d \
    --mount type=bind,src=<PATH TO .gitconfig>,dst=/home/rstudio/.gitconfig,readonly \
    ...
~~~

For example, share the current user's `.gitconfig` with

~~~bash
docker run -d \
    --mount type=bind,src="/$HOME/.gitconfig",dst=/home/rstudio/.gitconfig,readonly \
    ...
~~~

To use Git with SSH, grant the container access to the SSH credentials, by adding the following to the `docker run` call:

~~~bash
docker run -d \
    --mount type=bind,src=<PATH TO credentials>,dst=/home/rstudio/.ssh,readonly \
    ...
~~~

For example,

~~~bash
docker run -d \
    --mount type=bind,src="/$HOME/.ssh",dst=/home/rstudio/.ssh,readonly \
    ...
~~~
