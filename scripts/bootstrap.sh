#!/bin/bash

echo "helix-p4d container starting..."
echo "checking environment variables..."
if [ -z "$P4ROOT" ] || [ -z "$P4DEPOTS" ] || [ -z "$P4PORT" ] || [ -z "$SERVERID" ]; then
    echo "Error: P4ROOT, P4DEPOTS, P4PORT or SERVERID is not set. Please set these variables before running the script."
    exit 1
fi

echo "bootstrap with:"
echo "P4ROOT=$P4ROOT"
echo "P4DEPOTS=$P4DEPOTS"
echo "P4PORT=$P4PORT"
echo "SERVERID=$SERVERID"

echo "begin bootstrap..."
# Restore checkpoint if symlink latest exists
if [ -L "$P4CKP/latest" ]; then
    echo "Restoring checkpoint..."
	restore.sh
	rm "$P4CKP/latest"
else
	echo "Create empty or start existing server..."
	setup.sh
fi

p4 login <<EOF
$P4PASSWD
EOF

echo "checking status..."
p4dctl status -t p4d "$SERVERID"

running=true
graceful_shutdown() {
    echo "received signal, shutting down..."
    running=false
}

trap graceful_shutdown  HUP INT QUIT TERM SIGTERM

tail -f $P4ROOT/logs/log &

while $running; do
    sleep 2
done

echo "Gracefully shutting down Perforce Server..."
p4dctl stop -t p4d "$SERVERID"
until ! p4 info -s 2> /dev/null; do sleep 1; done
sleep 1
echo "Perforce Server is stopped."
