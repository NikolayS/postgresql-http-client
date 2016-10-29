Preparations
===

```
-- Postgres/Linux version: PostgreSQL 9.6.1 on x86_64-pc-linux-gnu, compiled by gcc (Debian 4.9.2-10) 4.9.2, 64-bit

-- pgsql-http (C)
create extension pgsql-http;-- https://github.com/pramsey/pgsql-http

-- plsh (curl)
create extension plsh;
create schema http_client;
create or replace function http_client._get(text, integer) returns text as $$
#!/bin/sh
curl -i --connect-timeout $2 "$1" 2>/dev/null
$$ language plsh;

-- plpython2u
create extension plpython2u;
create or replace function get(uri character varying) returns text as $$
  import urllib2
  data = urllib2.urlopen(uri)
  return data.read()
$$
language plpython2u volatile;

-- plpython3u
create extension plpython3u;
create or replace function get_python3(uri character varying) returns text as $$
  from urllib.request import urlopen
  data = urlopen(uri)
  return data.read()
$$
language plpython3u volatile;
```

Benchmarks
===
```sh
echo "select left(http_get.content, 50) from http_get('https://ya.ru');" > ~/http_c.sql
echo "select left(_get, 50) from http_client._get('https://ya.ru', 2);" > ~/http_plsh.sql
echo "select left(get, 50) from get('https://ya.ru');" > ~/http_python.sql
echo "select left(get_python3, 50) from get_python3('https://ya.ru');" > ~/http_python3.sql
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$ pgbench -f ~/http_c.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_c.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 235.928 ms
tps = 42.385814 (including connections establishing)
tps = 42.390860 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_plsh.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_plsh.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 306.951 ms
tps = 32.578475 (including connections establishing)
tps = 32.581800 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 233.735 ms
tps = 42.783469 (including connections establishing)
tps = 42.789140 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python3.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python3.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 234.199 ms
tps = 42.698796 (including connections establishing)
tps = 42.704341 (excluding connections establishing)
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$ ping ya.ru
PING ya.ru (213.180.204.3) 56(84) bytes of data.
64 bytes from www.yandex.ru (213.180.204.3): icmp_seq=1 ttl=57 time=41.9 ms
64 bytes from www.yandex.ru (213.180.204.3): icmp_seq=2 ttl=57 time=41.9 ms
64 bytes from www.yandex.ru (213.180.204.3): icmp_seq=3 ttl=57 time=41.9 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 41.927/41.962/41.982/0.024 ms
postgres@dev:~$ time curl https://ya.ru >/dev/null
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  9456  100  9456    0     0  38676      0 --:--:-- --:--:-- --:--:-- 38913
real    0m0.257s
user    0m0.012s
sys     0m0.004s
```

Conclusion
===
Results:

Method | Latency, ms | TPS
------------ | ------------- | -------------
pgsql-http (C) | 235.92 | 42.39
plsh (curl) | 306.95 | 32.58
plpython2u | 233.74 | 42.79
plpython3u | 234.20 | 42.70

The "plsh" approach has an obvious drawback: additional separate `curl` process is to be invoked for every query. 
As a result, it shows slower results compared to [pgsql-http](https://github.com/pramsey/pgsql-http) 
extension, written in C, and plpython2u-based function.

At the same time, plpython2u-based function showed very similar (sometimes even better) performance compared to pgsql-http.

There is practically no difference between plpython2u and plpython3u functions.

The bottom line: the [pgsql-http](https://github.com/pramsey/pgsql-http) doesn't seem to perform better than plpython2u function. The plpython2u-based approach wins because:
 - it's not slower than pgsql-http 
 - it's much easier to deploy.
