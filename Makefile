all: setup

config-copy:
	cp 'config/application.sample.yml' 'config/application.yml'

docker.start: config-copy
	docker-compose up -d && docker-compose run web rails db:migrate

docker.stop:
	docker-compose down
