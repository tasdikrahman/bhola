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
- /api/v1/domains GET should return the list of domains stored
- /api/v1/domains POST -d {'domain': 'foo.example.com'} should return 201 Created and store the domain in the db if
the domain is of valid format.

### What bhola is not

- will not generate certificates for you by being the intermediate broker
- will not install the certificates for it's clients
- will not provide a UI to generate/install/replace the certs for it's clients

### Backlog

- Send notifications to slack/mail.
- Have a front end to insert/show the domains which have expired
