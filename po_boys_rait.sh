#!/bin/bash
#
# Po Boys Rait
#

source config.sh

if [ ! -d ${WORKDIR}/splitfiles ]; then
    mkdir -p ${WORKDIR}/splitfiles
fi

if [ ! -d ${WORKDIR}/zfec ]; then
    mkdir -p ${WORKDIR}/zfec
fi

tar -cvf - ${INPUT_FOLDER} | zstdmt | split --bytes=${CHUNKSIZE} --numeric-suffixes --suffix-length=6 - ${WORKDIR}/splitfiles/backup.tar.zstd.part.
