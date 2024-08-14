#!/bin/bash

set -e

GOOD_IMG="httpd-bug-test:works"
GOOD_NAME="httpd_works"

BAD_IMG="httpd-bug-test:broken"
BAD_NAME="httpd_broken"

buildah bud -t $GOOD_IMG -f Dockerfile.works .
podman run --rm --name=$GOOD_NAME -p 8080:8080 -d $GOOD_IMG
timeout 3 curl localhost:8080/test || true

echo "======= logs from the version that works ==========="
podman logs $GOOD_NAME
podman stop $GOOD_NAME


buildah bud -t $BAD_IMG -f Dockerfile.broken .
podman run --rm --name=$BAD_NAME -p 8080:8080 -d $BAD_IMG
timeout 3 curl localhost:8080/test || true

echo "======= logs from the version that's broken ==========="
podman logs $BAD_NAME
podman stop $BAD_NAME