# httpd bug reproducer.

I think I've found a bug in apache httpd and this repository is meant to
reproduce that bug.

Run `run.sh` and the script will build and interact with two containers.

One based off of apache `2.4.50` that works and one based off of `2.4.62` that doesn't.

The script uses `podman` to build containers, but could easily be modified to use `docker`
instead.
