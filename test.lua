

function test_bug(r)
  r.filename = 'proxy:unix:/tmp/bug_test.sock|http://localhost/test'
  r.handler = "proxy-server"
  r.proxyreq = apache2.PROXYREQ_REVERSE
  
  return apache2.OK
end