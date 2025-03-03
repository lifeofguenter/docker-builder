SHELL := bash

bold := $(shell tput bold)
norm := $(shell tput sgr0)

# gh-actions shim
ifdef GITHUB_REPOSITORY
	REPO_NAME ?= $(shell echo '$(GITHUB_REPOSITORY)' | tr A-Z a-z)
endif

ifdef GITHUB_REF
ifneq (,$(findstring refs/heads/,$(GITHUB_REF)))
	GIT_BRANCH := $(GITHUB_REF:refs/heads/%=%)
else ifneq (,$(findstring refs/tags/,$(GITHUB_REF)))
	TAG_NAME := $(GITHUB_REF:refs/tags/%=%)
endif
endif

REPO_NAME ?= $(notdir $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..))/$(shell basename '$(PWD)')


$(info [REPO_NAME: $(REPO_NAME)])
$(info [GIT_BRANCH: $(GIT_BRANCH)])
$(info [TAG_NAME: $(TAG_NAME)])


.PHONY: all
all:


.PHONY: build
build:
	@echo -e "🔨👷 $(bold)Building$(norm) 👷🔨"
	docker build \
		--pull \
		--platform linux/amd64 \
		-t '$(REPO_NAME)' \
		.


.PHONY: test
test:
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'ansible --version'
	@echo -e "\n"
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'aws --version'
	@echo -e "\n"
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'b2 --version'
	@echo -e "\n"
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'gcloud --version'
	@echo -e "\n"
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'mysqldump --version'
	@echo -e "\n"
	docker run --rm --entrypoint bash '$(REPO_NAME)' -c 'docker --version'
	@echo -e "\n"


.PHONY: publish
publish: docker-login
ifeq ($(GIT_BRANCH),main)
	@echo -e "🚀🐳 $(bold)Publishing: $(REPO_NAME):latest$(norm) 🐳🚀"
	docker push '$(REPO_NAME)'
else ifdef TAG_NAME
	@echo -e "🚀🐳 $(bold)Publishing: $(REPO_NAME):$(TAG_NAME)$(norm) 🐳🚀"
	docker tag '$(REPO_NAME)' '$(REPO_NAME):$(TAG_NAME)'
	docker push '$(REPO_NAME):$(TAG_NAME)'
endif


.PHONY: docker-login
docker-login:
ifneq ($(GITHUB_ACTOR),dependabot[bot])
	$(call docker_login)
endif


define docker_login
	echo -n '$(DOCKER_PASSWORD)' | docker login -u lifeofguenter --password-stdin
endef
