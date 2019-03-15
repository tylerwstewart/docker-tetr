TAG_ORG = chazzam
TAG_NAME = tetr
TAG_FLAVOR = 10.0-x86
TAG_FLAVOR_LATEST = $(TAG_ORG)/$(TAG_NAME):$(TAG_FLAVOR)

all:
	docker build . -t $(TAG_FLAVOR_LATEST) -t $(TAG_ORG)/$(TAG_NAME):latest
