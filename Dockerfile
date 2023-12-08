# ----------------------------------------------------------------------------
#   Dockerfile for Perforce Helix Core Server
#   
#   this Dockerfile is based on Perforce's official Linux package-based installation
#   see https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.html
# ---------------------------------------------------------------------------- 

# note: not all versions of Ubuntu are supported by Perforce
# see https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.html#Prerequi
FROM ubuntu:jammy 

LABEL vendor="Riccici"
LABEL maintainer="Riccici (lqwork2023@gmail.com)"

# notice: in github actions, get warning "debconf: delaying package configuration, since apt-utils is not installed"
#         see https://github.com/phusion/baseimage-docker/issues/319
#         fix it by setting two environment variables below
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS="yes"

# Install prerequisites && add Perforce package repository
RUN \
    apt-get update && \
    apt-get install -y wget gnupg2 apt-utils


# Install Perforce package repository
# notice: in perforce's official document, perforce.pubkey save on /usr/share/keyrings/perforce.gpg
#         but in my case, it doesn't work in Dockerfile, save it on /etc/apt/trusted.gpg.d/perforce.gpg instead works well
RUN \
    wget -qO - https://package.perforce.com/perforce.pubkey | gpg --dearmor | tee /etc/apt/trusted.gpg.d/perforce.gpg > /dev/null && \
    echo "deb http://package.perforce.com/apt/ubuntu jammy release" > /etc/apt/sources.list.d/perforce.list && \
    apt-get update

# why this 5 packages? see https://www.perforce.com/manuals/p4sag/Content/P4SAG/install.linux.packages.install.html
RUN apt-get install -y helix-p4d helix-p4dctl helix-proxy helix-broker helix-cli

COPY --chmod=777 scripts/*.sh /usr/local/bin/

ENV P4ROOT=/p4 \
    P4DEPOTS=/p4/depots

# https://www.perforce.com/manuals/cmdref/Content/CmdRef/P4PORT.html
ARG p4port
ENV P4PORT=${p4port:-1666}

# server id https://www.perforce.com/manuals/cmdref/Content/CmdRef/P4NAME.html
ARG serverid
ENV SERVERID=${serverid:-helix-core-server}

# admin user default info
ARG adminuser
ARG adminpwd
ENV P4USER=${adminuser:-admin} \
    P4PASSWD=${adminpwd:-admin@password}

ARG typemapurl
ENV TYPEMAP_URL=${typemapurl}

EXPOSE $P4PORT
WORKDIR $P4ROOT
VOLUME $P4ROOT

ENTRYPOINT [ "/usr/local/bin/bootstrap.sh" ]

HEALTHCHECK \
    --interval=2m \
    --timeout=10s \
    CMD p4 info -s > /dev/null || exit 1
