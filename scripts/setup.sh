#!/bin/bash

echo "checking etc folder..."
if [ ! -d "$P4ROOT/etc" ]; then
    echo >&2 "First time installation, copying configuration from /etc/perforce to $P4ROOT/etc and relinking"
    mkdir -p "$P4ROOT/etc"
    cp -r /etc/perforce/* "$P4ROOT/etc/"
fi

echo "linking /etc/perforce to $P4ROOT/etc"
mv /etc/perforce /etc/perforce.orig
ln -s "$P4ROOT/etc" /etc/perforce

# setup depots directory
echo "checking depots directory..."
if [ ! -d "$P4DEPOTS" ]; then
    echo "Creating depots directory: $P4DEPOTS"
    mkdir -p "$P4DEPOTS"
    # https://www.perforce.com/manuals/cmdref/Content/CmdRef/p4_depot.html#Providin
    # set the depots root path
    echo "Setting depots root path: $P4DEPOTS"
    p4 configure set server.depot.root=$P4DEPOTS
fi

echo "checking server..."
if ! p4dctl list 2>/dev/null | grep -q "$SERVERID"; then

    echo "Creating server: $SERVERID"
    # -n:  Use the following flags in non-interactive mode (/opt/perforce/sbin/configure-helix-p4d.sh is interactive by default)
    # -p:   Perforce Server's address. because we are running in a container, we only need to listen on 0.0.0.0:P4PORT
    # -r:   Perforce Server's root directory. 
    # -u:   Perforce Server's super user.
    # -P:   Perforce Server's super user password.
    # --unicode: Enable Perforce Server's unicode support.
    # --case:  Perforce Server's case sensitivity. (0=sensitive[default],1=insensitive)
    /opt/perforce/sbin/configure-helix-p4d.sh "$SERVERID" -n -p "$P4PORT" -r "$P4ROOT" -u "$P4USER" -P "$P4PASSWD" --unicode --case 1
fi

echo "checking typemap..."
if [ ! -z "$TYPEMAP_URL" ]; then
    echo "Downloading typemap from $TYPEMAP_URL"
    wget $TYPEMAP_URL -q -O - | p4 typemap -i
fi