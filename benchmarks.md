Preparations
===

```sql
create extension pgsql-http;-- https://github.com/pramsey/pgsql-http

create extension plsh;
create schema http_client;
create or replace function http_client._get(text, integer) returns text as $$
#!/bin/sh
curl -i --connect-timeout $2 "$1" 2>/dev/null
$$ language plsh;

create extension plpython2u;
CREATE OR REPLACE FUNCTION get(uri character varying)
  RETURNS text AS
$BODY$
import urllib2
data = urllib2.urlopen(uri)
return data.read()
$BODY$
  LANGUAGE plpython2u VOLATILE COST 100;
```

Benchmarks
===
```sh
echo "select left(http_get.content, 50) from http_get('https://ya.ru');" > ~/http_c.sql
echo "select left(_get, 50) from http_client._get('https://ya.ru', 2);" > ~/http_plsh.sql
echo "select left(get, 50) from get('https://ya.ru');" > ~/http_python.sql
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$
postgres@dev:~$ pgbench -f ~/http_c.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_c.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 245.738 ms
tps = 40.693780 (including connections establishing)
tps = 40.746296 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_plsh.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_plsh.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 308.031 ms
tps = 32.464254 (including connections establishing)
tps = 32.496800 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 250.369 ms
tps = 39.941063 (including connections establishing)
tps = 39.991098 (excluding connections establishing)
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
100  9457  100  9457    0     0  30494      0 --:--:-- --:--:-- --:--:-- 30704

real    0m0.322s
user    0m0.016s
sys     0m0.000s
```

Conclusion
===
The "plsh" approach has an obvious drawback (additional `curl` process). 
As a result, it shows slower results compared to [pgsql-http](https://github.com/pramsey/pgsql-http) 
extension, written in C, and plpython2u-based function.

At the same time, plpython2u-based function showed slightly better performance compared to pgsql-http.
