build:
	podman-compose build

run:
	podman-compose down
	podman-compose up -d

enter:
	curl -X POST http://localhost:5000/stdin -H "Content-Type: application/json" -d "\"$(INPUT)\""

.PHONY: build run
