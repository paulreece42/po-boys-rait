# Po\' Boys' RAIT

Danger! This is only a fun proof of concept!

![your scientists were so preoccupied with whether or not they could, they didn't stop to think about whether or not they should](./jurassic_park.jpg)


RAIT stands for "redundant array of inexpensive tapes"

Another concept is "redundant array of inexpensive libraries" or RAIL

It seems that in the open source world, the only thing that really offers this _that I know of_ is Amanda

Anyways, all this is, is some shell scripts I wrote, that attempt to do this using a big temporary folder (ideally on SSD), to sort of slice and dice tar.zst files, split them, erasure code them using zfec, and write to 3 or more tape drives, ideally in parallel (or if not, you'll need temp space enough to store 3 full tapes)

You'll need: zfec, mbuffer, tar, zstd

    pip3 install zfec

ADDME
## How it works

Adjust your configs to "sane" values, remember that tapes get best performance with big long writes, and each chunk stops it. So 100GB chunks or so seems reasonable, but balance this with your /tmp dir size

Setup some crons to do some things, then run po_boys_rait.sh on the directory you want to archive

It'll tar it up, compress with zstd, chunk it into files of size whatever, dumping to a work folder as it goes

Then a cron will watch for files that haven't been modified in 1 minute (meaning: not still writing), run those through zfec and remove them

zfec cron outputs to yet another temp working directory, where each drive's cron looks for its own zfec files that haven't been written to in the last minute, and tars those to tape

Currently, each file is created as its own tar archive, meaning you have to while loop to extract. I debated using mbuffer or appending, but this won in the end

## Caveats

I'm probably going to change it to tar, split, then zstd. At first I didn't like this because all your chunks will be different sizes, and I was thinking of using chunks
the same size as the tape drive. But I don't know, using tar -M for multitape it sort of seems like what's the point... if you lose one zstd chunk, you can't (reliably) unzstd, whereas with tar I think you can still recover *some* data

You'll want to use this with an autoloader and setup tar with a command to grab the next tape, automatically

## Using

Again this is just a proof of concept

Now that that warning is outta the way:

### Backing Up

Setup your crons, they should not pile up, due to flock:

    * * * * * root /opt/po_boys_rait/zfec_cron.sh
    * * * * * root /opt/po_boys_rait/drive_runner_cron.sh 0 /dev/nst0
    * * * * * root /opt/po_boys_rait/drive_runner_cron.sh 1 /dev/nst1
    * * * * * root /opt/po_boys_rait/drive_runner_cron.sh 2 /dev/nst2

Right now I'm actually running those drive_runner_crons in named screens so when it prompts for next tape I can kindly do the needful by hand :-) _again: proof of concept_

Now run it on some big dir:

    /opt/po_boys_rait/po_boys_rait.sh /mnt/tank/mydir/.zfs/.snapshot/backup-2025-12-05/


### Resoring

Work in progress

I'm just testing with normal tar files, not tape drives (yet), so:

    mkdir /tmp/restore
    cd /tmp/restore

Delete one if you like to test EC:

    tar xvf /tmp/drive0
    tar xvf /tmp/drive1
    tar xvf /tmp/drive2

    # I only have 17 parts in my test, replace with your maxfile
    for i in {000000..000017} ; do zunfec -o backup.tar.zstd.part.${i} backup.tar.zstd.part.${i}.*fec && rm -f backup.tar.zstd.part.${i}.*fec; done;

    cat * | zstdcat | tar xvf -

## Erasure Coding

Think RAID-5 or RAID-6

In Erasure Coding, we use the concepts of _k_ and _m_

I'm a Ceph fanboy, Ceph gives a great overview of this, for example:

https://docs.ceph.com/en/latest/rados/operations/erasure-code/

k are data chunks, m are parity chunks.

So for k+m=4+2 EC, you'd need 6 tape drives total, but you could lose 2 tapes, on the third you lose data

I've just got a little library that only holds 3 HH-drives, so I'm going to use 2+1. 3 drives total, can lose one tape, on the second tape failure, all data is lost

zfec does this a bit differently


The higher the K, the less space you lose to parity, but the higher the stakes, because at m+1 failures, all data is lost. 

You can get quite creative with this. For example, Backblaze runs their EC on HDDs at 17+3, meaning they can store 20TB in only 23.6TB, and still lose up to 3 drives

Of course to do the same with tape, you'd need 20 tape drives, and enough bandwidth to meet the minimum write speed without shoe-shining, so that's probably exabyte scale



