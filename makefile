FRONTEND_DIR ?= ./web
BACKEND_DIR ?= .

IMAGE ?= xiao222aa/new-api
TAG ?= latest
LOCAL_COMPOSE_FILE ?= docker-compose.yml
PROD_COMPOSE_FILE ?= docker-compose.prod.yml

.DEFAULT_GOAL := help

.PHONY: help all build-frontend start-backend local-up local-ps \
	test-subscription build-prod push-tag push-latest push-prod release \
	deploy-prod deploy-prod-tag deploy-prod-script

help:
	@echo "Usage: make <target> [TAG=xxx]"
	@echo ""
	@echo "Dev targets:"
	@echo "  build-frontend      Build frontend with bun"
	@echo "  start-backend       Run backend locally"
	@echo "  local-up            docker compose up -d --build (local)"
	@echo "  local-ps            docker compose ps (local)"
	@echo "  test-subscription   go test ./model -run Subscription"
	@echo ""
	@echo "Release targets:"
	@echo "  build-prod          Build production image with VITE_BASE=/newapi/"
	@echo "  push-tag            Push $(IMAGE):$(TAG)"
	@echo "  push-latest         Tag $(IMAGE):$(TAG) as latest and push"
	@echo "  push-prod           push-tag + push-latest"
	@echo "  release             build-prod + push-prod"
	@echo ""
	@echo "Deploy targets:"
	@echo "  deploy-prod         Deploy latest via compose file"
	@echo "  deploy-prod-tag     Deploy TAG via NEW_API_TAG"
	@echo "  deploy-prod-script  Deploy via scripts/deploy-prod.sh"
	@echo ""
	@echo "Examples:"
	@echo "  make release TAG=v20260316-1"
	@echo "  make deploy-prod-tag TAG=v20260316-1"

all: build-frontend start-backend

build-frontend:
	@echo "Building frontend..."
	@cd $(FRONTEND_DIR) && bun install && DISABLE_ESLINT_PLUGIN='true' VITE_REACT_APP_VERSION=$$(cat VERSION) bun run build

start-backend:
	@echo "Starting backend dev server..."
	@cd $(BACKEND_DIR) && go run main.go &

local-up:
	@echo "Starting local services with build..."
	@docker compose -f $(LOCAL_COMPOSE_FILE) up -d --build

local-ps:
	@docker compose -f $(LOCAL_COMPOSE_FILE) ps

test-subscription:
	@echo "Running subscription tests..."
	@cd $(BACKEND_DIR) && go test ./model -run Subscription

build-prod:
	@echo "Building production image $(IMAGE):$(TAG) ..."
	@docker build --build-arg VITE_BASE=/newapi/ -t $(IMAGE):$(TAG) .

push-tag:
	@echo "Pushing $(IMAGE):$(TAG) ..."
	@docker push $(IMAGE):$(TAG)

push-latest:
	@echo "Tagging and pushing latest ..."
	@docker tag $(IMAGE):$(TAG) $(IMAGE):latest
	@docker push $(IMAGE):latest

push-prod: push-tag push-latest

release: build-prod push-prod
	@echo "Release completed: $(IMAGE):$(TAG) and $(IMAGE):latest"

deploy-prod:
	@echo "Deploying latest with compose..."
	@docker compose -f $(PROD_COMPOSE_FILE) up -d
	@docker compose -f $(PROD_COMPOSE_FILE) ps

deploy-prod-tag:
	@echo "Deploying tag $(TAG) with compose..."
	@NEW_API_TAG=$(TAG) docker compose -f $(PROD_COMPOSE_FILE) up -d
	@docker compose -f $(PROD_COMPOSE_FILE) ps

deploy-prod-script:
	@echo "Deploying with scripts/deploy-prod.sh ..."
	@NEW_API_TAG=$(TAG) ./scripts/deploy-prod.sh
