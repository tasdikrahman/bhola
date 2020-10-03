## CHANGELOG

### v0.1.0
#### Added
- everything in https://github.com/tasdikrahman/bhola/milestone/1
- But to summarise
    - A basic UI to view the domains and an API to insert and start tracking domains

### v0.2.0
#### Added
- Added Dockerfile for bhola
- Added docker-compose setup
- Pushing container images for bhola for each commit to ghcr.io and docker hub
- Added ability to send expiry notifications via slack, putting it behind feature flag
    - env vars to be set SLACK_WEBHOOK_URL and SEND_EXPIRY_NOTIFICATIONS_TO_SLACK
