
all: build

build:
	@./build.sh "https://github.com/deis/example-go" "heroku/cedar:14"

