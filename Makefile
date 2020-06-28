SHELL = /bin/sh

#import environment variables
$(shell if [ ! -f ".env" ]; then cp .env.example .env; fi)
include .env

#check arch for install jq package
ARCH := $(shell arch)
JQx64 = 'http://stedolan.github.io/jq/download/linux64/jq'
JQx32 = 'http://stedolan.github.io/jq/download/linux32/jq'

install:
	wget -c https://erachain.org/assets/ERA/Erachain.tar.gz -O - | tar -xz
	@if [ '$(ARCH)' = 'x86_64' ]; then wget $(JQx64); else wget $(JQx32); fi
	@chmod +x ./jq
	@sudo cp jq /usr/bin
	@rm jq
	@if [ '${NAME}' = '' ]; then echo "\e[32mВведите название вашего блокчейна:\e[0m"; \
	read BLOCKCHAIN_NAME; sed -ir "s/NAME=.*/NAME=$${BLOCKCHAIN_NAME}/" .env; \
	else BLOCKCHAIN_NAME=${NAME}; fi; \
	wget -O first_genesis.json "https://side.erachain.org/api/get-genesis?seed=${SEED_FIRST}&name=$${BLOCKCHAIN_NAME}"
	wget -O second_genesis.json "https://side.erachain.org/api/get-genesis?seed=${SEED_SECOND}&onlySeed"
	@if [ '${SEED_FIRST}' = '' ]; then FIRST_SEED=`cat first_genesis.json | jq '.seed' | tr -d "\""`; \
	cat .env | sed -ir "s/SEED_FIRST=.*/SEED_FIRST=$${FIRST_SEED}/" .env; fi
	@if [ '${PASSWORD_FIRST}' = '' ]; then PASS_FIRST=`base64 /dev/urandom | head -10 | tr -d -c '0-9' | cut -c1-8`; \
    cat .env | sed -ir "s/PASSWORD_FIRST=.*/PASSWORD_FIRST=$${PASS_FIRST}/" .env; fi
	@if [ '${SEED_FIRST}' = '' ]; then SECOND_SEED=`cat second_genesis.json | jq '.seed' | tr -d "\""`; \
	cat .env | sed -ir "s/SEED_SECOND=.*/SEED_SECOND=$${SECOND_SEED}/" .env; fi
	@if [ '${PASSWORD_SECOND}' = '' ]; then PASS_SECOND=`base64 /dev/urandom | head -10 | tr -d -c '0-9' | cut -c1-8`; \
    cat .env | sed -ir "s/PASSWORD_SECOND=.*/PASSWORD_SECOND=$${PASS_SECOND}/" .env; fi
	@cat first_genesis.json | jq '.data' > Settings/sideGENESIS.json
	@rm first_genesis.json
	@rm second_genesis.json
	@if [ -f ".envr" ]; then rm .envr; fi
	@echo "\e[31mВАЖНО!!!\e[0m"
	@echo "В файле .env записаны сиды от первой и второй ноды. Сохраните их в надежное место. При утере сида, восстановление доступа к кошельку невозможно."

start:
	@docker-compose up