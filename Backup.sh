#!/bin/bash

DIRECTORY='/var/www'
TODIRECTORY='/srv/backup'
OK='/tmp/suc.log'
NO='/tmp/fail.log'

if tar -cvf "$TODIRECTORY"/Backup-$(date +%d.%m.%Y).tar "$DIRECTORY" 1>>'$OK' 2>>'$NO'
then
echo "successful ($OK)"
else
echo "bad ($NO)"
fi

if find /srv/backup -name Backup-* -mtime +7 -delete
then
echo "files is deleted +7d"
else
echo "error"
fi