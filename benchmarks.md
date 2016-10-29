```sh
postgres@dev:~$ pgbench -f ~/http_plsh.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_plsh.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 308.225 ms
tps = 32.443874 (including connections establishing)
tps = 32.476145 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_c.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_c.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 313.396 ms
tps = 31.908481 (including connections establishing)
tps = 31.938834 (excluding connections establishing)
postgres@dev:~$ pgbench -f ~/http_python.sql -c 10 -t 10 test
starting vacuum...end.
transaction type: /var/lib/postgresql/http_python.sql
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 100/100
latency average = 240.904 ms
tps = 41.510259 (including connections establishing)
tps = 41.565650 (excluding connections establishing)
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
Although "plsh" approach has an obvious drawback (additional `curl` process), 
it shows results very similar to [pgsql-http](https://github.com/pramsey/pgsql-http) 
extension, written in C. At the same time, plpython2u solutions shows significantly better results.
