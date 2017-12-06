create extension if not exists plpython2u;

create schema http_client;

do $$
begin
    execute 'alter database '||current_database()||' set http_client.connect_timeout = 2;';
    execute 'alter database '||current_database()||' set http_client.default_headers = ''{}'';';
end;
$$ language plpgsql;

create type http_client.response as (
    url_requested text,
    url_received text,
    status_code integer,
    headers json,
    body text,
    is_json boolean
);

create or replace function http_client._get(url text, timeout integer, headers jsonb) returns http_client.response as $$
try:
    from urllib2 import Request, urlopen, HTTPError
    import json
    res = {}
    res['url_requested'] = url
    res['body'] = res['status_code'] = res['url_received'] = None
    res['is_json'] = res['headers'] = None
    try:
        req = Request(url)
        if headers:
            for k, v in json.loads(headers).iteritems():
                req.add_header(k, v)
        conn = urlopen(req, timeout = timeout)
        res['body'] = conn.read()
        res['status_code'] = conn.getcode()
        res['url_received'] = conn.geturl()
        respHeaders = conn.info().dict
        conn.close()
    except HTTPError as e:
        res['status_code'] = e.code
        respHeaders = e.headers.dict # undocumented http://stackoverflow.com/a/6402083/4677351
        res['body'] = e.read()
    res['headers'] = json.dumps(respHeaders)
    if 'content-type' in respHeaders and respHeaders['content-type'].find('application/json') >= 0:
        res['is_json'] = True
    else:
        res['is_json'] = False
    return res
except Exception as e:
    msg = "Error in http_clien._get(): exception {0} occured."
    res = msg.format(e.__class__.__name__)
    return res
$$ language plpython2u volatile;

create or replace function http_client.get(query text, headers jsonb) returns http_client.response as $$
    select http_client._get(
        query,
        coalesce(nullif(current_setting('http_client.connect_timeout', true), ''), '2')::integer,
        coalesce(nullif(current_setting('http_client.default_headers', true), ''), '{}')::jsonb || coalesce(headers, '{}'::jsonb)
    );
$$ language sql volatile;

create or replace function http_client.get(query text) returns http_client.response as $$
    select http_client.get(query, '{}'::jsonb);
$$ language sql volatile;

