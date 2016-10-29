# postgresql-http-client
Simple HTTP client inside your PostgreSQL. Easy to install. No compilation required: no gcc, no `make && make install`. Made with two extensions, plpgsql and plsh.

Allows GET and POSTS requests in SQL environment:

```sql
test=# \x
Expanded display is on.
test=# select (get).* from http_client.get('http://ya.ru');
-[ RECORD 1 ]--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
status_code | 302
status_line | HTTP/1.1 302 Found
headers     | {"P3P": "policyref=\"/w3c/p3p.xml\", CP=\"NON DSP ADM DEV PSD IVDo OUR IND STP PHY PRE NAV UNI\"", "Date": "Sat, 29 Oct 2016 00:08:43 GMT", "Server": "nginx", "Expires": "Sat, 29 Oct 2016 00:08:44 GMT", "Location": "https://ya.ru/", "Connection": "keep-alive", "Set-Cookie": "yandexuid=182183081477699724; Expires=Tue, 27-Oct-2026 00:08:43 GMT; Domain=.ya.ru; Path=/", "Cache-Control": "no-cache,no-store,max-age=0,must-revalidate", "Last-Modified": "Sat, 29 Oct 2016 00:08:44 GMT", "Content-Length": "0"}
body        |
body_jsonb  |
is_json     | f
```

Another example, showing work with REST API:
```sql
test=# with data as (
  select (get).*
  from http_client.get('http://pokeapi.co/api/v2/pokemon/')
), results as (
  select jsonb_array_elements(body_jsonb->'results') r from data
)
select r->>'url' as url, r->>'name' as pokename
from results
order by pokename
limit 5;
                 url                  |  pokename
--------------------------------------+------------
 http://pokeapi.co/api/v2/pokemon/15/ | beedrill
 http://pokeapi.co/api/v2/pokemon/9/  | blastoise
 http://pokeapi.co/api/v2/pokemon/1/  | bulbasaur
 http://pokeapi.co/api/v2/pokemon/12/ | butterfree
 http://pokeapi.co/api/v2/pokemon/10/ | caterpie
(5 rows)
```
