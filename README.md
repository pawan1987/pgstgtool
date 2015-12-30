# Pgstgtool

Tool helps to create postgres staging end point on standby nodes using lvm snapshot feature.

### Version
0.0.2

### Config file format

Config

```sh
global do
  proddir_pattern '/var/lib/pgsql/VERSION/APP'
  datadir_pattern '/mnt/postgres/VERSION/APP'
  task_dir '/etc/pgstgtool/tasks'
  logfile '/tmp/pgstgtool_log'
  snapshot_size_min '90480k'
  loglevel 'Debug'
end

app 'data' do
  port 5461
  version '9.4'
  size 99
end
```
* task: rake task to run post staging end point
* size: lvm snapshot size. Can be specified in multiple of bytes (e.g. '10m') or simple number '10' (percentage of size origin logical volume). default value is 10. 
* prod_mount: Datadir of running postgres service for which the staging point needs to be created. if prod_mount is not specified explicitly for the app, the tool will derive it from prod_dir_patter(if defined in global parameter) replacing 'APP' keyword with appname. Similar is the case for stage_mount.
* stage_mount: Mount point for staging service.
* task_dir: task dir which contains the specified 'task' file.

### Task file

```sh
task :default do
  puts "Postgres is running on port #{ENV['PORT']} with datadir #{ENV['PGDATA']}"
end
```

Both PGDATA (postgres staging dir) and PORT (staging port) will be passed to rake task as environment variables


Contributor
----

- [pawan pandey]

