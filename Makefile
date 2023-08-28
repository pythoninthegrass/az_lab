#!/usr/bin/env make

.DEFAULT_GOAL		:= help
export SHELL 		:= /bin/bash

# env vars
export NAME			:= testvm
export IMAGE		:= 22.04
export CPU			:= 2
export DISK			:= 5G
export MEM			:= 1G
export CONF			:= cloud-init.ubuntu.yml

# colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

# targets
.PHONY: all
all: list launch info shell stop start delete purge ansible

ifneq ($(shell command -v multipass >/dev/null 2>&1; echo $$?), 0)
	$(error "multipass is not installed")
endif

launch: ## launch a new instance of ubuntu
	@echo "${YELLOW}Launching a new instance of ubuntu${RESET}"
	multipass launch \
		--name "${NAME}" "${IMAGE}" \
		--cpus "${CPU}" \
		--disk "${DISK}" \
		--memory "${MEM}" \
		--cloud-init "${CONF}" \
		--verbose

list:
	@echo "${YELLOW}Listing instances${RESET}"
	multipass list

info: ## show info about the instance
	@echo "${YELLOW}Showing info about the instance${RESET}"
	multipass info --format yaml "${NAME}"

shell: ## open a shell in the instance
	@echo "${YELLOW}Opening a shell in the instance${RESET}"
	multipass shell "${NAME}"

mount: ## mount volume in instance
	@echo "${YELLOW}Mounting the instance${RESET}"
	multipass mount $(shell pwd) "${NAME}":/home/ubuntu/apt_lab_tf

stop: ## stop the instance
	@echo "${YELLOW}Stopping the instance${RESET}"
	multipass stop "${NAME}"

start: ## start the instance
	@echo "${YELLOW}Starting the instance${RESET}"
	multipass start "${NAME}"

delete: stop ## delete the instance
	@echo "${YELLOW}Deleting the instance${RESET}"
	multipass delete "${NAME}"

purge: ## purge all instances
	@echo "${YELLOW}Purging all instances${RESET}"
	multipass purge

run: ## run ansible playbook
	@echo "${YELLOW}Running ansible playbook${RESET}"
	#!/usr/bin/env bash
	# set -euxo pipefail
	multipass exec "${NAME}" -- \
		ansible-playbook \
			/home/ubuntu/apt_lab_tf/ansible/playbook.yml \
			--tags qa \
			-vvv

precommit: ## update pre-commit hooks
	@echo "${YELLOW}Updating pre-commit hooks${RESET}"
	pre-commit autoupdate

help: ## show this help
	@echo ''
	@echo 'Usage:'
	@echo '    ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)
