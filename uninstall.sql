do $$
begin
    execute 'alter database '||current_database()||' reset http_client.connect_timeout;';
end;
$$ language plpgsql;

drop schema http_client cascade;
