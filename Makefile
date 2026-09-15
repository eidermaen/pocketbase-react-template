.PHONY: dev migrate test build docker-build docker-up docker-down

dev:
	go run ./cmd/start serve --dev --dir ./pb_data

migrate:
	go run ./cmd/start migrate up --dir ./pb_data

test:
	go test -v ./...

build:
	cd frontend && npm run build
	go build -o bin/app ./cmd/start

docker-build:
	docker build -t pbapp-template .

docker-up:
	docker compose up -d

docker-down:
	docker compose down
