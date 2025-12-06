#!/bin/bash
#
# cron to check folder for files not still being written to, and zfec them, removing originals
#

source config.sh

# from the flock man page, keeps your crons from piling up!
[ ${FLOCKER} != $0 ] && exec env FLOCKER="$0 flock -en $0 $0 $@ ||

find ${WORKDIR}/splitfiles -mmin +1 -type f -execdir zfec -m 3 -k 2 -d ${WORKDIR}/zfec/ {} \; -execdir rm -f {} \;
