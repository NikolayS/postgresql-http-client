The Benchmark of Different Approaches to Do HTTP Requests from PostgreSQL
===

TL;DR: jump to [Conclusions](#conclusions)

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

Let's test 3 cases:
 - http, localhost
 - http, ya.ru (answers with redirect, empty body)
 - https, ya.ru

```sh
postgres@dev:~$ #### http, localhost
postgres@dev:~$ echo "select left(http_get.content, 50) from http_get('http://localhost/robots.txt');" > ~/local_http_c.sql
postgres@dev:~$ echo "select left(_get, 50) from http_client._get('http://localhost/robots.txt', 2);" > ~/local_http_plsh.sql
postgres@dev:~$ echo "select left(get, 50) from get('http://localhost/robots.txt');" > ~/local_http_python.sql
postgres@dev:~$ echo "select left(get_python3, 50) from get_python3('http://localhost/robots.txt');" > ~/local_http_python3.sql
postgres@dev:~$ pgbench -f ~/local_http_c.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/local_http_c.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 5.013 ms
tps = 1994.932871 (including connections establishing)
tps = 2007.401692 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/local_http_plsh.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/local_http_plsh.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 19.199 ms
tps = 520.853950 (including connections establishing)
tps = 521.675404 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/local_http_python.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/local_http_python.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 2.203 ms
tps = 4539.882871 (including connections establishing)
tps = 4602.161543 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/local_http_python3.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/local_http_python3.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 3.180 ms
tps = 3144.268470 (including connections establishing)
tps = 3175.129339 (excluding connections establishing)
postgres@dev:~$ 
postgres@dev:~$ 
postgres@dev:~$ #### http, ya.ru
postgres@dev:~$ echo "select left(http_get.content, 50) from http_get('http://ya.ru/robots.txt');" > ~/http_c.sql
postgres@dev:~$ echo "select left(_get, 50) from http_client._get('http://ya.ru/robots.txt', 2);" > ~/http_plsh.sql
postgres@dev:~$ echo "select left(get, 50) from get('http://ya.ru/robots.txt');" > ~/http_python.sql
postgres@dev:~$ echo "select left(get_python3, 50) from get_python3('http://ya.ru/robots.txt');" > ~/http_python3.sql
postgres@dev:~$ pgbench -f ~/http_c.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_c.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 106.253 ms
tps = 94.115185 (including connections establishing)
tps = 94.141779 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_plsh.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_plsh.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 121.416 ms
tps = 82.361461 (including connections establishing)
tps = 82.382124 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 106.056 ms
tps = 94.290085 (including connections establishing)
tps = 94.317153 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python3.sql -c 10 -t 100 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python3.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 106.013 ms
tps = 94.327689 (including connections establishing)
tps = 94.352006 (excluding connections establishing)
postgres@dev:~$ 
postgres@dev:~$
postgres@dev:~$ #### https, ya.ru
postgres@dev:~$ echo "select left(http_get.content, 50) from http_get('https://ya.ru');" > ~/https_c.sql
postgres@dev:~$ echo "select left(_get, 50) from http_client._get('https://ya.ru', 2);" > ~/https_plsh.sql
postgres@dev:~$ echo "select left(get, 50) from get('https://ya.ru');" > ~/https_python.sql
postgres@dev:~$ echo "select left(get_python3, 50) from get_python3('https://ya.ru');" > ~/https_python3.sql
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$ pgbench -f ~/https_c.sql -c 10 -t 100 test
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
postgres@dev:~$ pgbench -f ~/https_plsh.sql -c 10 -t 100 test
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
postgres@dev:~$ pgbench -f ~/https_python.sql -c 10 -t 100 test
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
postgres@dev:~$ pgbench -f ~/https_python3.sql -c 10 -t 100 test
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

Memory consumption:
```
postgres@dev:~$  ### pgsql-http (C)
postgres@dev:~$  ps -u postgres uf
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
postgres 13381  2.0  0.1 4613684 24672 ?       Ss   07:34   0:00  \_ postgres: postgres test [local] SELECT
postgres@dev:~$  ### plsh
postgres@dev:~$  ps -u postgres uf
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
postgres  7805  0.2  0.1 4525780 19324 ?       Ss   07:33   0:00  \_ postgres: postgres test [local] SELECT
postgres  8672  0.0  0.0 135024  3288 ?        S    07:33   0:00  |   \_ /bin/sh /tmp/plsh-hDxrRx https://ya.ru 2
postgres  8673  0.0  0.0 272324  7732 ?        S    07:33   0:00  |       \_ curl -i --connect-timeout 2 -H Accept: application/json https://ya.ru application/json https://ya.ru
postgres@dev:~$  ### plpython2u
postgres@dev:~$  ps -u postgres uf
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
postgres 12235  3.0  0.1 4553668 29636 ?       Ss   07:34   0:00  \_ postgres: postgres test [local] SELECT
postgres@dev:~$  ### plpython3u
postgres@dev:~$  ps -u postgres uf
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
postgres 10812  3.3  0.1 4562784 32000 ?       Ss   07:33   0:00  \_ postgres: postgres test [local] SELECT
```

Conclusions
---
### Results for HTTP, localhost:

Method | Latency, ms | TPS
------------ | ------------- | -------------
pgsql-http (C) | 5.01 | 2007
plsh (curl) | 19.20 | 521.6
plpython2u | 2.20 | 4602
plpython3u | 3.18 | 3175

### Results for HTTP, ya.ru:

Method | Latency, ms | TPS
------------ | ------------- | -------------
pgsql-http (C) | 106.2 | 94.14
plsh (curl) | 121.4 | 82.38
plpython2u | 106.0 | 94.32
plpython3u | 106.0 | 94.35

### Results for HTTPS, ya.ru:

Method | Latency, ms | TPS | RSS, MB
------------ | ------------- | ------------- | -------------
pgsql-http (C) | 235.92 | 42.39 | ~24
plsh (curl) | 306.95 | 32.58 | ~30 (19324kB+3288kB+7732kB)
plpython2u | 233.74 | 42.79 | ~30
plpython3u | 234.20 | 42.70 | ~32

The "plsh" approach has an obvious drawback: additional separate `curl` process is to be invoked for every query. 
As a result, it shows slower results compared to [pgsql-http](https://github.com/pramsey/pgsql-http) 
extension, written in C, and plpython2u-based function.

At the same time, plpython2u-based function showed very similar (sometimes even better) performance compared to pgsql-http.

There is practically no difference between plpython2u and plpython3u functions.

The bottom line: the [pgsql-http](https://github.com/pramsey/pgsql-http) doesn't seem to perform better than plpython2u function. However, pgsql-http is better in terms of memory consumption (in the examples above, postgres+plpythonu took ~20% more RAM than postgres backends with pgsql-http; for plsh, postgres backend combined with curl process took the same RAM resources as postgres+plpythonu backend).

The plpython2u-based approach wins because:
 - it's definitely not slower than pgsql-http (sometimes even faster)
 - it's much easier to deploy.
 - RAM consumption is not signifcantly worse than in case of pgsql-http
 
Credits
===
Many thanks to [@ruslantalpa](https://github.com/ruslantalpa) for great suggestions.
