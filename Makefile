OS_NAME := $(shell uname)
ifeq ($(OS_NAME), Darwin)
OPEN := open
else
OPEN := xdg-open
endif

qa: analyse test

analyse:
	@go vet ./...

test:
	@go test -cover ./...

benchmark:
#	$ needs to be escaped by $$ in Makefiles
	@go test -bench=. -run=^$$ ./...

coverage:
	@mkdir -p ./coverage
	@go test -coverprofile=./coverage/cover.out ./...
	@go tool cover -html=./coverage/cover.out -o ./coverage/cover.html
	@$(OPEN) ./coverage/cover.html

clean:
	@rm -rf build/

build: qa clean
	$(eval VERSION=$(shell git tag --points-at HEAD))
	$(eval VERSION=$(or $(VERSION), (version unavailable)))

	@GOOS=darwin GOARCH=arm64 go build -ldflags="-X 'github.com/thenativeweb/eventsourcingdb/version.Version=$(VERSION)'" -o ./build/eventsourcingdb-darwin-arm64
	@GOOS=darwin GOARCH=amd64 go build -ldflags="-X 'github.com/thenativeweb/eventsourcingdb/version.Version=$(VERSION)'" -o ./build/eventsourcingdb-darwin-amd64
	@GOOS=linux GOARCH=amd64 go build -ldflags="-X 'github.com/thenativeweb/eventsourcingdb/version.Version=$(VERSION)'" -o ./build/eventsourcingdb-linux-amd64
	@GOOS=windows GOARCH=amd64 go build -ldflags="-X 'github.com/thenativeweb/eventsourcingdb/version.Version=$(VERSION)'" -o ./build/eventsourcingdb-windows-amd64.exe

build-docker: build
	$(eval VERSION=$(shell git tag --points-at HEAD))
	$(eval IMAGE_VERSION=$(or $(VERSION), latest))
	$(eval VERSION=$(or $(VERSION), (version unavailable)))

	docker build --build-arg version="$(VERSION)" -t thenativeweb/eventsourcingdb:latest -t thenativeweb/eventsourcingdb:$(IMAGE_VERSION) .

.PHONY: analyse benchmark build build-docker clean coverage qa test