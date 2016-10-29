The Benchmark of Different Approaches to Do HTTP Requests from PostgreSQL
===

Preparations
---

```
-- Postgres/Linux version: PostgreSQL 9.6.1 on x86_64-pc-linux-gnu, compiled by gcc (Debian 4.9.2-10) 4.9.2, 64-bit

-- pgsql-http (C)
create extension http; -- https://github.com/pramsey/pgsql-http - compile&install it beforehand

-- plsh (curl)
create extension plsh; -- do beforehand: sudo apt-get install postgresql-9.6-plsh
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
create extension plpython3u; -- do beforehand: sudo apt-get install postgresql-plpython3-9.6
create or replace function get_python3(uri character varying) returns text as $$
  from urllib.request import urlopen
  data = urlopen(uri)
  return data.read()
$$
language plpython3u volatile;
```

Benchmark
---
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
postgres@dev:~$ ping -c 500 ya.ru # check that RTT to ya.ru is VERY stable
PING ya.ru (213.180.193.3) 56(84) bytes of data.
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=1 ttl=56 time=55.5 ms
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=2 ttl=56 time=55.5 ms
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=3 ttl=56 time=55.5 ms
...
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=497 ttl=56 time=55.5 ms
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=498 ttl=56 time=55.5 ms
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=499 ttl=56 time=55.5 ms
64 bytes from www.yandex.ru (213.180.193.3): icmp_seq=500 ttl=56 time=55.5 ms

--- ya.ru ping statistics ---
500 packets transmitted, 500 received, 0% packet loss, time 499791ms
rtt min/avg/max/mdev = 55.462/55.546/55.884/0.243 ms

--- ya.ru ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4006ms
rtt min/avg/max/mdev = 55.539/55.548/55.558/0.258 ms
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$ # curl is less stable, but also not bad
postgres@dev:~$ for i in {1..5}; do time curl https://ya.ru >/dev/null 2> /dev/null; done 

real    0m0.257s
user    0m0.016s
sys     0m0.000s

real    0m0.286s
user    0m0.016s
sys     0m0.004s

real    0m0.287s
user    0m0.012s
sys     0m0.000s

real    0m0.252s
user    0m0.008s
sys     0m0.004s

real    0m0.252s
user    0m0.016s
sys     0m0.000s
```

Conclusion
---
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
