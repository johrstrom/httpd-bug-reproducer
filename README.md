# httpd bug reproducer.

I think I've found a bug in apache httpd (https://bz.apache.org/bugzilla/show_bug.cgi?id=69261)
and this repository is meant to demonstrate and reproduce that bug.

Run `run.sh` and the script will build and interact with two containers.

One based off of apache `2.4.50` that works and one based off of `2.4.62` that doesn't.

The script uses `podman` to build containers, but could easily be modified to use `docker`
instead.

When the script uses `curl` to the Location that's been added - we can see logs like this where
the request is sucessfully being reverse proxied back to the UDS socket that was started in the
container's entrypoint.

```
[Wed Aug 14 16:06:11.632955 2024] [proxy:trace2] [pid 8:tid 137483257747200] proxy_util.c(2355): [client 10.0.2.100:40248] *: using default reverse proxy worker for unix:/tmp/bug_test.sock|http://localhost/test (no keepalive)
[Wed Aug 14 16:06:11.632958 2024] [proxy:trace2] [pid 8:tid 137483257747200] proxy_util.c(2312): [client 10.0.2.100:40248] *: rewrite of url due to UDS(/tmp/bug_test.sock): http://localhost/test (proxy:http://localhost/test)
[Wed Aug 14 16:06:11.632960 2024] [proxy:debug] [pid 8:tid 137483257747200] mod_proxy.c(1504): [client 10.0.2.100:40248] AH01143: Running scheme unix handler (attempt 0)
[Wed Aug 14 16:06:11.632967 2024] [proxy_wstunnel:trace5] [pid 8:tid 137483257747200] mod_proxy_wstunnel.c(340): [client 10.0.2.100:40248] handler fallback
[Wed Aug 14 16:06:11.632974 2024] [proxy_http:trace1] [pid 8:tid 137483257747200] mod_proxy_http.c(1875): [client 10.0.2.100:40248] HTTP: serving URL http://localhost/test
[Wed Aug 14 16:06:11.632981 2024] [proxy:debug] [pid 8:tid 137483257747200] proxy_util.c(2528): AH00942: http: has acquired connection for (*)
[Wed Aug 14 16:06:11.632984 2024] [proxy:debug] [pid 8:tid 137483257747200] proxy_util.c(2583): [client 10.0.2.100:40248] AH00944: connecting http://localhost/test to localhost:80
[Wed Aug 14 16:06:11.632985 2024] [proxy:debug] [pid 8:tid 137483257747200] proxy_util.c(2620): [client 10.0.2.100:40248] AH02545: http: has determined UDS as /tmp/bug_test.sock
[Wed Aug 14 16:06:11.633037 2024] [proxy:debug] [pid 8:tid 137483257747200] proxy_util.c(2806): [client 10.0.2.100:40248] AH00947: connected /test to httpd-UDS:0
[Wed Aug 14 16:06:11.633062 2024] [proxy:debug] [pid 8:tid 137483257747200] proxy_util.c(3177): AH02823: http: connection established with Unix domain socket /tmp/bug_test.sock (*)
```

Version `2.4.62` however fails, with these entries in the log. And indeed the result from `curl` shows httpd
returns a 500 error page. `2.4.62` cannot determine the correct handler for the request. Notably `mod_proxy_http` declines
the URL.

```
[Wed Aug 14 16:06:31.593622 2024] [proxy:trace2] [pid 11:tid 28] proxy_util.c(2625): [client 10.0.2.100:50980] *: using default reverse proxy worker for unix:/tmp/bug_test.sock|http://localhost/test (no keepalive)
[Wed Aug 14 16:06:31.593624 2024] [proxy:debug] [pid 11:tid 28] mod_proxy.c(1465): [client 10.0.2.100:50980] AH01143: Running scheme unix handler (attempt 0)
[Wed Aug 14 16:06:31.593628 2024] [proxy_wstunnel:trace5] [pid 11:tid 28] mod_proxy_wstunnel.c(364): [client 10.0.2.100:50980] handler fallback
[Wed Aug 14 16:06:31.593633 2024] [proxy_http:debug] [pid 11:tid 28] mod_proxy_http.c(1901): [client 10.0.2.100:50980] AH01113: HTTP: declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593637 2024] [proxy_fcgi:debug] [pid 11:tid 28] mod_proxy_fcgi.c(1078): [client 10.0.2.100:50980] AH01076: url: unix:/tmp/bug_test.sock|http://localhost/test proxyname: (null) proxyport: 0
[Wed Aug 14 16:06:31.593639 2024] [proxy_fcgi:debug] [pid 11:tid 28] mod_proxy_fcgi.c(1083): [client 10.0.2.100:50980] AH01077: declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593643 2024] [proxy_scgi:debug] [pid 11:tid 28] mod_proxy_scgi.c(547): [client 10.0.2.100:50980] AH00865: declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593646 2024] [:debug] [pid 11:tid 28] mod_proxy_uwsgi.c(512): [client 10.0.2.100:50980] declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593652 2024] [proxy_ajp:debug] [pid 11:tid 28] mod_proxy_ajp.c(785): [client 10.0.2.100:50980] AH00894: declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593659 2024] [proxy_connect:trace1] [pid 11:tid 28] mod_proxy_connect.c(177): [client 10.0.2.100:50980] declining URL unix:/tmp/bug_test.sock|http://localhost/test
[Wed Aug 14 16:06:31.593664 2024] [proxy_ftp:trace3] [pid 11:tid 28] mod_proxy_ftp.c(1014): [client 10.0.2.100:50980] declining URL unix:/tmp/bug_test.sock|http://localhost/test - not ftp:
[Wed Aug 14 16:06:31.593665 2024] [proxy:warn] [pid 11:tid 28] [client 10.0.2.100:50980] AH01144: No protocol handler was valid for the URL /test (scheme 'unix'). If you are using a DSO version of mod_proxy, make sure the proxy submodules are included in the configuration using LoadModule.
10.0.2.100 - - [14/Aug/2024:16:06:31 +0000] "GET /test HTTP/1.1" 500 531
```