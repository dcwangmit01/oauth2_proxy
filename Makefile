.DEFAULT_GOAL=help

DOCKER_REGISTRY   ?=
IMAGE_PREFIX      ?= ciscosso
SHORT_NAME        ?= oauth2_proxy
VERSION           ?= test
TARGETS           ?= linux/amd64
BASE_IMAGE        ?= $(IMAGE_PREFIX)/$(SHORT_NAME)

# go option
GO        ?= go
PKG       :=
TAGS      :=
TESTS     := .
TESTFLAGS :=
LDFLAGS   := -w -s
LDFLAGS   += -extldflags "-static"
GOFLAGS   :=
GOSOURCES  = $(shell find main.go ./cmd ./pkg -type f -name '*.go')
BINDIR    := $(CURDIR)/bin

LDFLAGS += -extldflags "-static"


gofmt:   ## Format all golang code
	gofmt -w -s $(GOSOURCES)

gosources:
	@echo $(GOSOURCES)

tags:
	etags $(GOSOURCES)

build:  ## Build locally for all os/arch combinations in ./_dist
	CGO_ENABLED=0 gox -parallel=3 \
	  -output="_dist/{{.OS}}-{{.Arch}}/{{.Dir}}" \
	  -osarch='$(TARGETS)' $(GOFLAGS) $(if $(TAGS),-tags '$(TAGS)',) \
	  -ldflags '$(LDFLAGS)' ./

docker-build: ## Build the docker image
	@#docker pull $(BASE_IMAGE):build-cache || true

	docker build \
	  --tag $(BASE_IMAGE):build-cache \
	  --cache-from $(BASE_IMAGE):build-cache \
	  .

	@# Then retag as the new version
	docker tag $(BASE_IMAGE):build-cache $(BASE_IMAGE):$(VERSION)

docker-push: ## Publish the docker image
	@echo "Executing docker push for build"
	echo "$${DOCKER_PASSWORD}" | docker login -u "$${DOCKER_USERNAME}" --password-stdin

	@# Push cached build layers first
	docker push $(BASE_IMAGE):build-cache
	docker push $(BASE_IMAGE):$(VERSION)

clean:  ## Clean up the build dirs
	@rm -rf $(BINDIR) ./_dist ./bin vendor .vendor-new .venv

help:  ## Print list of Makefile targets
	@# Taken from https://github.com/spf13/hugo/blob/master/Makefile
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  cut -d ":" -f1- | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
