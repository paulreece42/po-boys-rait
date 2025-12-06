#!/bin/bash
#
# cron for each drive
#
# pass drive args like so:
#
# drive index matches filename:
#  /tmp/work/zfec/backup.tar.zstd.part.000000.0_3.fec
#
#  ./drive_runner.sh index device
#  ./drive_runner.sh 0 /dev/nst0
#
# be sure to use the NON-REWINDING tape drive, i.e. /dev/nst
# not the rewinding one, /dev/st, which will overwrite your data!
#

source config.sh

# from the flock man page, keeps your crons from piling up!
[ ${FLOCKER} != $0 ] && exec env FLOCKER="$0 flock -en $0 $0 $@ ||

index=$1
tape_device=$2

# if not writing to a real tape device, i.e. just a tar file, remove -M and -c and add -r
find ${WORKDIR}/zfec/ -iname "*${index}_${KM}.fec" -mmin +1 -execdir tar -rvf ${tape_device} {} --remove-files \;
#find ${WORKDIR}/zfec/ -iname "*${index}_${KM}.fec" -mmin +1 -execdir tar -cvMf ${tape_device} {} --remove-files \;
