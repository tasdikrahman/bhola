# BHOLA
### Problem statement

- No visibility about when the certificate, of when is it expiring
- No alerts in form of email or test message when the certificate is expiring
- Very reactive in nature on when the certificate expires

#### v0.1

- Will have a list of domains which it queries, which gets triggered by a schedule processor which checks every day on
a specific time, each and every domain in it's database
    - if the domain has expired
        - mark it as expired in the database 
    - if the domain has not expired
        - don't do anything
- the timeframe as of now can be set to 10days before the certificate expires
- Rails console to be used to insert into the database for now. 
- `/api/v1/domains` `GET` should return the list of domains stored
- `/api/v1/domains POST -d {'domain': 'foo.example.com'}` should return 201 Created and store the domain in the db if
the domain is of valid format.

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
$ RAILS_ENV=test rails db:drop db:create db:migrate
$ bundle exec rspec
```

### Api docs
- inserting domain to be tracked
```
$ curl --location --request POST 'localhost:3000/api/v1/domains' \
--header 'Content-Type: application/json' \
--data-raw '{
    "fqdn": "foo.example.com"
}'
```
- querying a domain stored
```
$ curl --location --request GET 'localhost:3000/api/v1/domains/1'
```

### What bhola is not/will not be

- will not generate certificates for you by being the intermediate broker
- will not install the certificates for it's clients
- will not provide a UI to generate/install/replace the certs for it's clients

## Progress

- [ ] v0.1 [https://github.com/tasdikrahman/bhola/milestone/1](https://github.com/tasdikrahman/bhola/milestone/1)

### Backlog

- Send notifications to slack/mail.
    - send it to the user mentioned email id's, for each domain
- Have a front end to insert/show the domains which have expired/when they are expiring
