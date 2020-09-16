# BHOLA
### Problem statement

- No visibility about when the certificate is expiring
- No alerts in form of email or test message when the certificate is expiring

which makes the process very reactive when the certificate expires

#### v0.1

- Will have a list of domains which it queries, which gets triggered by a scheduled job which checks on a predefined
time interval, each and every domain in it's database
    - if the domain has expired
        - mark it as expired in the database 
    - if the domain has not expired
        - don't do anything
- the timeframe should be configurable via env var
- Should have a route to insert/query domains
- `/api/v1/domains` `GET` should return the list of all domains stored
- `/api/v1/domains POST -d {'domain': 'foo.example.com'}` should return 201 Created and store the domain in the db

##### Assumptions for v0.1

- the user is inserting a valid domain which also has an ssl certificate attached to it

## Running it

```
# start server process
$ bundle exec rails s -b 0.0.0.0 -p 3000
# start the clockwork process
$ bundle exec clockwork clock.rb
```

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
set to minimum coverage of [99% as of now](https://github.com/tasdikrahman/bhola/pull/40/)

### Api docs
- inserting domain to be tracked
```
$ curl --location --request POST 'localhost:3000/api/v1/domains' \
--header 'Content-Type: application/json' \
--data-raw '{
    "fqdn": "foo.example.com"
}'
```
- querying the domains stored
```
$ curl --location --request GET 'localhost:3000/api/v1/domains' \
 --header 'Accept: application/json'
{
  "data": [
    {
      "fqdn": "foo.example.com",
      "certificate_expiring": false
    },
    {
      "fqdn": "bar.example.com",
      "certificate_expiring": false
    }
  ],
  "errors": []
}
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
- Validate the domain being inserted
    - whether it's a valid registered domain or not
    - has an x509 cert attached to it
