SHELL := /bin/bash
IMAGE := secret-test
SECRET_STRING := hoge
DOCKERFILES := $(wildcard ./Dockerfile.*)

.PHONY: default
default: help

.PHONY: help help-common
help: help-common help-task-list

help-common:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m %-30s\033[0m %s\n", $$1, $$2}'

define run-tasks
PHONY: $(1) help-$(1)
$(1):
	@echo
	@echo "#################################################################################"
	@echo "## Dockerfile.$1 を利用したテスト"
	@echo "#################################################################################"
	@echo 
	@echo "## Dockerfile.$1 の確認"
	@echo 
	cat Dockerfile.$1
	@echo 
	@echo "## Dockerfile.$1 で build を実施"
	@echo "##  - 期待通り秘密の文字列が使われていることを確認"
	@echo "##  - 想定外のところで秘密の文字列が出力されてたりしないか確認"
	@echo 
	docker build -t $(IMAGE):$1 -f Dockerfile.$1 --build-arg SECRET_STRING=$(SECRET_STRING) .
	@echo 
	@echo "## Docker history で秘密の文字列が埋めこまれていないか確認"
	@echo 
	docker history --no-trunc $(IMAGE):$1 | sed -E 's/(hoge)/\o033[32m\1\o033[39m/g'

help-$(1):
	@printf "\033[36m %-30s\033[0m %s\n" "$1" "Dockerfile.$1 を利用してテスト"
endef

$(foreach _dockerfile,$(DOCKERFILES),$(eval $(call run-tasks,$(_dockerfile:./Dockerfile.%=%)))):

.PHONY: help-task-list
help-task-list: $(addprefix help-,$(DOCKERFILES:./Dockerfile.%=%))

.PHONY: test-all
test-all: $(DOCKERFILES:./Dockerfile.%=%) ## すべてのテストを実行
