# org and name tags
TAG_ORG := chazzam
TAG_NAME := tetr


# Setup TC Version tag
TC_VERSION := 10.0


# Setup current version tags
TAG_FLAVOR := $(TC_VERSION)-x86
TAG_FLAVOR_64 := $(TC_VERSION)-x86_64
DOCKER_FROM := tatsushid/tinycore:$(TAG_FLAVOR)
DOCKER_FROM_64 := tatsushid/tinycore:$(TAG_FLAVOR_64)


# Build up the tags for building the x86 and x86_64 images
TAG_FLAVOR_LATEST = $(TAG_ORG)/$(TAG_NAME):$(TAG_FLAVOR)
TAG_FLAVOR_LATEST_64 = $(TAG_ORG)/$(TAG_NAME):$(TAG_FLAVOR_64)
DOCKER_TAGS := -t $(TAG_FLAVOR_LATEST) -t $(TAG_ORG)/$(TAG_NAME):latest
DOCKER_TAGS_64 := -t $(TAG_FLAVOR_LATEST_64) -t $(TAG_ORG)/$(TAG_NAME):latest-x86_64


# combine all the docker args together
DOCKER_ARGS := --build-arg DOCKER_FROM=$(DOCKER_FROM) $(DOCKER_TAGS)
DOCKER_ARGS_64 := --build-arg DOCKER_FROM=$(DOCKER_FROM_64) $(DOCKER_TAGS_64)


.PHONY: all force force_64 force_all x86 x86_64


all: x86 x86_64

force_all: force force_64

x86:
	docker build . $(DOCKER_ARGS)

x86_64:
	docker build . $(DOCKER_ARGS_64)

force:
	docker build --no-cache . $(DOCKER_ARGS)

force_64:
	docker build --no-cache . $(DOCKER_ARGS_64)
