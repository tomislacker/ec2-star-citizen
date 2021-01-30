SHELL := /bin/bash
PWD     := $(shell pwd)
DIRNAME := $(shell basename $(PWD))

STACK_PREFIX := $(DIRNAME)
HASHP1       := $(shell git log -n 1 --format=%H)
HASHP2       := $(shell git diff 2>>/dev/null | wc -l)
HASHP3       := $(shell [[ $(HASHP2) -ne 0 ]] && echo -dirty)
HASH         := $(HASHP1)$(HASHP3)

.PHONY: h
h :
	@echo HASHP1 = $(HASHP1)
	@echo HASHP2 = $(HASHP2)
	@echo HASHP3 = $(HASHP3)
	@echo HASH   = $(HASH)

.DEFAULT_GOAL := ec2

.PHONY : clean
clean :
	echo >&2 "$@ NOT IMPLEMENTED"
	false
.PHONY        : clean-aws-ec2
clean-aws-ec2 :
	@echo
	@echo Removing CFN stack $(STACK_PREFIX)-ec2 ...
	aws cloudformation delete-stack \
		--stack-name $(STACK_PREFIX)-ec2 \
		|| true # Ignore failures, assume maybe it's already gone

.PHONY               : clean-aws-persistentvpc
clean-aws-persistent : clean-aws-ec2
	@echo
	@echo Removing CFN stack $(STACK_PREFIX)-persistent
	aws cloudformation delete-stack \
		--stack-name $(STACK_PREFIX)-persistent \
		|| true # Ignore failures, assume maybe it's already gone

.PHONY    : clean-aws
clean-aws : | clean-aws-persistent
	@echo $@ complete

.PHONY : ec2
ec2    :
	@echo
	@echo Deploying $(STACK_PREFIX)-$@ ...
	aws cloudformation deploy \
		--capabilities \
			CAPABILITY_AUTO_EXPAND \
			CAPABILITY_IAM \
			CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			StackPrefix=$(STACK_PREFIX) \
			UserIp=$(shell curl -s ipv4.icanhazip.com) \
		--stack-name $(STACK_PREFIX)-$@ \
		--tags \
			'Purpose=$(STACK_PREFIX)' \
			'Hash=$(HASH)' \
		--template-file templates/$@.yml

.PHONY     : persistent
persistent :
	@echo
	@echo Deploying $(STACK_PREFIX)-$@ ...
	aws cloudformation deploy \
		--capabilities \
			CAPABILITY_AUTO_EXPAND \
			CAPABILITY_IAM \
			CAPABILITY_NAMED_IAM \
		--stack-name $(STACK_PREFIX)-$@ \
		--tags \
			'Purpose=$(STACK_PREFIX)' \
			'Hash=$(HASH)' \
		--template-file templates/$@.yml
