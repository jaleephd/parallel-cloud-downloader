# Parallel Cloud Downloader

A distributed (patent) downloader (and metadata extractor) that runs across several Linux instances on the cloud.

This was developed to assist a researcher in downloading terrabytes of data from a patent repository and extracting the metadata.
While it's use was specific, it could be easily adapted to download, and process, other large datasets in parallel.

It's design assumes that it is being run on Linux (Centos 6.5 was used) with one server running an NFS server
(or other form of shared file system) and acting as the master, while other Linux instances run as slaves,
coordinating with the master via the shared file system. It also assumes that the scripts are in the same
directory (generally the same directory as it is run from), and that the data is download into a
sub directory of this.

## Source Files

The scripts in the `src` directory are the main components of the system.

### graballrt.sh

graballrt is the main program and controls the other components. This is the program to
start the downloads going.

Usage: `graballrt.sh [-v] [-u base-URL] [-m maxjobs] [-x extract-dir] csvfile`.

This script downloads multiple series of zipped patent files from the patent repository,
according to the ranges specified in the csv file, which is the script's only compulsary argument.
For each range, zipped files are downloaded into its directory, while extracted files are
placed in the specified sub-directory.
The optional -m parameter gives the maximum number of parallel downloads, the default is 20.
The -v flag is for verbose (debugging or monitoring) output. Other parameters are self
explanatory.

To run it in parallel across several instances, it should be run on each one using the same
csv file.

### rtdl.sh

The rtdl.sh script downloads a series of zipped patent files from the patent repository.
The -v flag is for verbose (debugging or monitoring) output. Other parameters are self
explanatory.
It is called by graballrt.sh.
 
Usage: `rtdl [-v] [-u base-URL] [-s suffix] [-d directory] [-m maxjobs] first [last]`

### get_rt_archive.sh

The `get_rt_archive.sh` script downloads a zipped patent file from a patent archive.
The -v flag is for verbose (debugging or monitoring) output.
It is called by rtdl.sh.

Usage: `get_rt_archive.sh [-v] baseurl, directory, file, suffix, index, urlcount`

### unpackrt.sh

The `unpackrt.sh` script extracts the patent metadata (`*.tsv` files) and optionally
(if given the -z flag) zips the resulting data up into an archive.
It is called by graballrt.sh.

Usage: `unpackrt.sh [-z] series-dir dest-dir`

### kill_graball.sh

The `kill_graball.sh` script script gracefully shuts down the running graballrt.sh process
allowing it to complete the current downloads before exiting.

Usage: `kill_graball.sh`

### onfull_graball.sh

The `onfull_graball.sh` script is used to deal with when the disk becomes close to full,
and is generally called by a periodic cron job. Note that it must be run in the same directory
as the downloads.

It takes 3 parameters, with the first specifying the action to be taken in case the disk
is considered full, being one of 'stop' to simply stop further downloads, 'delete' to delete the
oldest download, or 'kill' to abort the graballrt.sh program (this can only be done from the
server). The second parameter specifies the filesystem to monitor, for example /data1,
and the last specifies the fullness threshold percentage (integer), for example '45' for 45%.

Usage: `onfull_graball.sh (stop | delete | kill) DISK THRESHOLD`

### dlmon.sh

dlmon.sh is a simple script for monitoring the progress of the downloads.
It takes 2 optional parameters, the first being number of latest '.error' files
to watch (default 1), and the second is the number of lines in those files to
show (default is 10).

Usage: `dlmon.sh [nfiles [nlines]]`


## Example crontab

There are 2 example crontabs in the crontab directory. These monitor disk space and either
delete the oldest (rtdl-master_crontab.sh) or exit after current downloads (rtdl-slave_crontab.sh).

## Example Download List

An example list of patent series to download is provided by rt_download_list.csv in the download_list directory.


