# Parallel Cloud Downloader

A distributed (patent) downloader (and metadata extractor) that runs across several Linux instances on the cloud.

This was developed to assist a researcher in downloading terrabytes of data from a patent repository and extracting the metadata.
While it's use was specific, it could be easily adapted to download, and process, other large datasets in parallel.

It's design assumes that it is being run on Linux (Centos 6.5 was used) with one server running an NFS server
(or other form of shared file system) and acting as the master, while other Linux instances run as slaves,
coordinating with the master via the shared file system.

