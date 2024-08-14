#!/bin/bash

set -e

su -s /bin/bash -c "ncat -e /bin/cat -U /tmp/bug_test.sock -lk" daemon &

/usr/local/apache2/bin/httpd -DFOREGROUND


