# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config/image.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

IMAGE_VERSION    := $(shell git describe --always)
IMAGE_TAG        := "$(IMAGE):$(IMAGE_VERSION)"
LATEST_IMAGE_TAG := "$(IMAGE):latest"

.PHONY: build
build:
	docker build -t $(IMAGE_TAG) .
	docker tag $(IMAGE_TAG) $(LATEST_IMAGE_TAG)

.PHONY: push
push:
	docker push $(IMAGE_TAG)
	docker push $(LATEST_IMAGE_TAG)
