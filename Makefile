MAKEFILE_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
SOURCE_ROOT_DIR:=$(abspath $(dir $(MAKEFILE_PATH)))

IMAGE_PREFIX ?= zephyr
IMAGE_VERSION := $(shell \
	if git rev-parse --git-dir > /dev/null 2>&1; then \
		TAG=$$(git name-rev --tags --name-only $$(git rev-parse HEAD) | sed 's/v//g;s/\^.*//g'); \
		if [ "$$TAG" = "undefined" ]; then \
			BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
			if [ "$$BRANCH" = "main" ]; then \
				echo "latest"; \
			else \
				echo "$$(echo $$BRANCH | sed 's|/|-|g')"; \
			fi; \
		else \
			echo "$$TAG"; \
		fi; \
	else \
		echo latest; \
	fi)

ifneq ($(value REGISTRY_URL),)
	IMAGE_TAG_BASE := $(REGISTRY_URL)/$(IMAGE_PREFIX)-base:$(IMAGE_VERSION)
	IMAGE_TAG_ARM_EABI := $(REGISTRY_URL)/$(IMAGE_PREFIX)-arm-zephyr-eabi:$(IMAGE_VERSION)
else
	IMAGE_TAG_BASE := $(IMAGE_PREFIX)-base:$(IMAGE_VERSION)
	IMAGE_TAG_ARM_EABI := $(IMAGE_PREFIX)-arm-zephyr-eabi:$(IMAGE_VERSION)
endif

.PHONY: all build build-base build-arm-zephyr-eabi login push prune

all: build

build-base:
	docker buildx build \
		--platform linux/amd64 \
		-t $(IMAGE_TAG_BASE) \
		-f $(SOURCE_ROOT_DIR)/base.Dockerfile .

build-arm-zephyr-eabi: build-base
	docker buildx build \
		--platform linux/amd64 \
		--build-arg BASE_IMAGE=$(IMAGE_TAG_BASE) \
		-t $(IMAGE_TAG_ARM_EABI) \
		-f $(SOURCE_ROOT_DIR)/arm-zephyr-eabi.Dockerfile .

build: build-base build-arm-zephyr-eabi

ifneq ($(value REGISTRY_URL),)
login:
	echo "$(REGISTRY_TOKEN)" | docker login $(REGISTRY_URL) -u $(REGISTRY_USER) --password-stdin

push: build
	docker push $(IMAGE_TAG_BASE)
	docker push $(IMAGE_TAG_ARM_EABI)
else
prune:
	docker image prune
endif
