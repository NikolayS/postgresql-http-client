do $$
begin
    execute 'alter database '||current_database()||' reset http_client.connect_timeout;';
    execute 'alter database '||current_database()||' reset http_client.default_headers;';
end;
$$ language plpgsql;

drop schema http_client cascade;
