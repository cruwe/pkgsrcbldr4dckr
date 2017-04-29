# docker-pkgsrcbldr

docker-pkgsrcbldr allows to build docker images containing necessary build
dependencies to bootstrap pkgsrc and to run parallel builds using the pbulk
framework.

## Provision Image

An image may be provisioned calling
```bash
docker build --build-arg=uid=<uid> -t <prefix>/pkgsrc-fedora-bldr -f Dockerfile.fedora .
```
from the context of the repositories base directory. Passing a uid as build
argument allows to map the pbulk build user to map against a valid user on the
docker host, so that packages are owned by that user and can be processed
further on the host.

## Bootstrap pbulk

pbulk, needed for (parallel) builds may be provisioned calling
```bash
docker run \
    -v <path_to_pkg_repo>:/data \ 
    -v <path_to_pkgsrc_repo>:/data/pkgsrc \
    -e RELEASE=2017Q1 \
    -ti <yourprefix>/pkgsrc-fedora-bldr \
    /root/bootstrap-pbulk.sh
```
A pbulk boostrap .tgz will then be placed into <path_to_pkgsrc_repo> to be
used by consecutive builds. Calling with the environment variable $RELEASE is
necessary to determine _what_ to build and the bootstrap will fail without.

Futher configuration may be passed by passing corresponding environment
variables, care to examine boostrap-pbulk.sh for options.

## Bootstrap the prefix

The prefix required for building and boostrapping on the target system may be
provisioned calling
```bash
docker run \
    -v <path_to_pkg_repo>:/data \ 
    -v <path_to_pkgsrc_repo>:/data/pkgsrc \
    -e RELEASE=2017Q1 \
    -ti <yourprefix>/pkgsrc-fedora-bldr \
    /root/bootstrap-prefix.sh
```
A prefix boostrap .tgz will then be placed into <path_to_pkgsrc_repo> to be
used by consecutive builds and to bootstrap non-compiling target hosts from.
Calling with the environment variable $RELEASE is necessary to determine
_what_ to build and the bootstrap will fail without.

Futher configuration may be passed by passing corresponding environment
variables, care to examine boostrap-pbulk.sh for options.

## Build packages

Packages may be build calling
```bash
docker run \
    -v <path_to_pkg_repo>:/data \ 
    -v <path_to_pkgsrc_repo>:/data/pkgsrc \
    -v <path_to_pkglist>:/pkglist \
    -e RELEASE=2017Q1 \
    -ti <yourprefix>/pkgsrc-fedora-bldr \
    /root/bulkcompile.sh
```
Packages will then be placed into the pkg_repo which is passed as an
environment variable, sub-divided under $RELEASE/$OS/$OS_VERSION/All.

## Caveats

The scripts cd to and clean the git directory passes as volume. *Any
un-commited will be cleaned - deleted*.

Although pbulk runs under the permissions of an unprivileged user, care to
note that the scripts bootstrapping and calling run as (containered) root.
Accordingly, when passing directories as volumes into docker, the containerd
root _inside_ the docker container may _do anything_ with these directories.
