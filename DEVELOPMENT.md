## Dev setup

```
$ docker run --name postgres -e POSTGRES_PASSWORD=password -e POSTGRES_USER=bhola_dev -e POSTGRES_DB=bhola_dev -p 5432:5432 -d postgres:12.3
```

#### Connecting to the local database

```
$ psql -h localhost -p 5432 -U bhola_dev -d bhola_dev
Password for user bhola_dev:
psql (12.3)
Type "help" for help.

bhola_dev=# \l
                                  List of databases
   Name    |   Owner   | Encoding |  Collate   |   Ctype    |    Access privileges
-----------+-----------+----------+------------+------------+-------------------------
 bhola_dev | bhola_dev | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres  | bhola_dev | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | bhola_dev | UTF8     | en_US.utf8 | en_US.utf8 | =c/bhola_dev           +
           |           |          |            |            | bhola_dev=CTc/bhola_dev
 template1 | bhola_dev | UTF8     | en_US.utf8 | en_US.utf8 | =c/bhola_dev           +
           |           |          |            |            | bhola_dev=CTc/bhola_dev
(4 rows)

bhola_dev=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 bhola_dev | Superuser, Create role, Create DB, Replication, Bypass RLS | {}

bhola_dev=#
```

#### Installing the postgresql client

```
# For arch based systems
$ sudo pacman -S postgresql-libs
```

### Running specs

```
# assuming you have run are running the postgres container already
$ cp config/application.sample.yaml config/application.yml
$ RAILS_ENV=test rails db:drop db:create db:migrate
$ bundle exec rspec
```

Not sure as of now, on how to display the codecoverage on the repo-readme as we are using github pipelines, but it's
set to minimum coverage of [99.4% as of now](https://github.com/tasdikrahman/bhola/blob/master/spec/spec_helper.rb#L21)