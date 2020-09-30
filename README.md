# BHOLA
### Problem statement

- No visibility about when the certificate is expiring
- No alerts in form of email or test message when the certificate is expiring

which makes the process very reactive when the certificate expires

![Imgur Image](https://user-images.githubusercontent.com/4672518/93598889-f8c3f500-f9da-11ea-98ca-a55fff2023fc.png)

## Running it

```
# Add appropriate values in application.yaml
$ cp config/application.sample.yaml config/application.yml

# start server process
$ bundle exec rails s -b 0.0.0.0 -p 3000

# start the clockwork process
$ bundle exec clockwork clock.rb

# open on your browser localhost:3000
```

Or if you prefer a single command

```
# requires docker-compose on your machine
$ make docker.start

# open localhost:8080 on browser
```

## Assumptions made by Bhola

- bhola assumes that the dns being inserted, resolves to a single IP, so in case you are doing
dns loadbalancing on a single FQDN, with multiple IP's behind it, it may try connecting to
whichever IP first get's returned.
- bhola will not register the domain to be tracked, if it can't reach it, it would be apt to place
bhola somewhere, in your network, which would make it possible for bhola to resolve your dns endpoints
with ease, so in case, the domains which you are trying to track, if they resolve to a private IP, make
sure bhola can reach them.
- bhola will not register the domain to be tracked, if it doesn't have an SSL cert attached, it will
not track it.

## Dev setup

Please refer [DEVELOPMENT.md](https://github.com/tasdikrahman/bhola/blob/master/DEVELOPMENT.md)

### Api docs
####  inserting domain to be tracked
##### Example request
```
$ curl --location --request POST 'localhost:3000/api/v1/domains' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "fqdn": "https://expired.badssl.com"
  }'
```

##### Example response
```
{
    "data": {
        "fqdn": "expired.badssl.com",
        "certificate_expiring": true,
        "certificate_issued_at": "2016-08-08T21:17:05.000Z",
        "certificate_expiring_at": "2018-08-08T21:17:05.000Z",
        "certificate_issuer": "/C=US/ST=California/L=San Francisco/O=BadSSL/CN=BadSSL Intermediate Certificate Authority"
    },
    "errors": []
}
```
#### querying the domains stored
##### Example request
```
$ curl --location --request GET 'localhost:3000/api/v1/domains' \
  --header 'Accept: application/json'
```

##### Example response
```
{
    "data": [
        {
            "fqdn": "tasdikrahman.me",
            "certificate_expiring": false,
            "certificate_issued_at": "2020-05-06T00:00:00.000Z",
            "certificate_expiring_at": "2022-04-14T12:00:00.000Z",
            "certificate_issuer": "/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert SHA2 High Assurance Server CA"
        },
        {
            "fqdn": "expired.badssl.com",
            "certificate_expiring": true,
            "certificate_issued_at": "2016-08-08T21:17:05.000Z",
            "certificate_expiring_at": "2018-08-08T21:17:05.000Z",
            "certificate_issuer": "/C=US/ST=California/L=San Francisco/O=BadSSL/CN=BadSSL Intermediate Certificate Authority"
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

- [x] v0.1 [https://github.com/tasdikrahman/bhola/milestone/1](https://github.com/tasdikrahman/bhola/milestone/1)
    - Will have a list of domains which it queries, which gets triggered by a scheduled job which checks on a predefined
time interval, each and every domain in it's database
        - if the domain has expired
            - mark it as expired in the database
        - if the domain has not expired
            - don't do anything
    - the timeframe for checking if cert has expired, should be configurable via env var
    - Should have a route to insert/query domains
    - `/api/v1/domains` `GET` should return the list of all domains stored
    - `/api/v1/domains POST -d {'domain': 'foo.example.com'}` should return 201 Created and store the domain in the db
    - validate domain being inserted
        - don't persist
            - if it doesn't have a cert attached
            - the domain is invalid
            - POST /api/v1/domains should return 422 as status code, along with the appropriate error message
    - deployment docs for running on VM
- [ ] v0.2 [https://github.com/tasdikrahman/bhola/milestone/2](https://github.com/tasdikrahman/bhola/milestone/2)
    - send notifications of expiry to slack
    - e2e tests on CI
    - create container image on each git push and push to a container registry
    - have helm chart for deployment
