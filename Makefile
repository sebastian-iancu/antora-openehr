.PHONY: help build build-local clean preview docker-build docker-up docker-down \
        clone-repos create-branches migrate-repo validate-structure install-deps

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configuration
REPOS_DIR := repos
BUILD_DIR := build
SPECS_REPOS := specifications-BASE specifications-RM
#SPECS_REPOS := specifications-BASE specifications-RM specifications-AM \
#               specifications-LANG specifications-SM specifications-QUERY \
#               specifications-PROC specifications-CDS specifications-CNF \
#               specifications-ITS-REST specifications-ITS-JSON specifications-ITS-XML specifications-ITS-BMM

##@ General

help: ## Display this help message
	@echo "$(CYAN)openEHR Antora Migration & Build System$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(CYAN)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Docker Operations

docker-build: ## Build the Docker image
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker-compose build

docker-up: ## Start Docker containers
	@echo "$(GREEN)Starting Docker containers...$(NC)"
	docker-compose up -d

docker-down: ## Stop Docker containers
	@echo "$(YELLOW)Stopping Docker containers...$(NC)"
	docker-compose down

docker-shell: docker-up ## Open a shell in the Antora container
	@echo "$(GREEN)Opening shell in Antora container...$(NC)"
	docker-compose exec antora /bin/bash

##@ Repository Management

clone-repos: ## Clone all openEHR specification repositories
	@echo "$(GREEN)Cloning openEHR specification repositories...$(NC)"
	@mkdir -p $(REPOS_DIR)
	@for repo in $(SPECS_REPOS); do \
		if [ ! -d "$(REPOS_DIR)/$$repo" ]; then \
			echo "$(CYAN)Cloning $$repo...$(NC)"; \
			git clone https://github.com/openEHR/$$repo.git $(REPOS_DIR)/$$repo; \
		else \
			echo "$(YELLOW)$$repo already exists, skipping...$(NC)"; \
		fi \
	done
	@echo "$(GREEN)Done cloning repositories.$(NC)"

update-repos: ## Update all cloned repositories
	@echo "$(GREEN)Updating all repositories...$(NC)"
	@for repo in $(SPECS_REPOS); do \
		if [ -d "$(REPOS_DIR)/$$repo" ]; then \
			echo "$(CYAN)Updating $$repo...$(NC)"; \
			cd $(REPOS_DIR)/$$repo && git fetch --all && cd ../..; \
		fi \
	done
	@echo "$(GREEN)Done updating repositories.$(NC)"

create-branches: ## Create release branches from git tags (usage: make create-branches REPO=specifications-BASE)
	@if [ -z "$(REPO)" ]; then \
		echo "$(RED)Error: REPO variable not set. Usage: make create-branches REPO=specifications-BASE$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Creating release branches from tags in $(REPO)...$(NC)"
	@./scripts/create-release-branches.sh $(REPOS_DIR)/$(REPO)

create-all-branches: clone-repos ## Create release branches for all repositories
	@echo "$(GREEN)Creating release branches for all repositories...$(NC)"
	@for repo in $(SPECS_REPOS); do \
		echo "$(CYAN)Processing $$repo...$(NC)"; \
		make create-branches REPO=$$repo; \
	done
	@echo "$(GREEN)Done creating branches for all repositories.$(NC)"

##@ Migration Operations

migrate-repo: ## Migrate a single repository to Antora structure (usage: make migrate-repo REPO=specifications-BASE)
	@if [ -z "$(REPO)" ]; then \
		echo "$(RED)Error: REPO variable not set. Usage: make migrate-repo REPO=specifications-BASE$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Migrating $(REPO) to Antora structure...$(NC)"
	@./scripts/migration/migrate-repo.sh $(REPOS_DIR)/$(REPO)

migrate-all: clone-repos ## Migrate all repositories to Antora structure
	@echo "$(GREEN)Migrating all repositories to Antora structure...$(NC)"
	@for repo in $(SPECS_REPOS); do \
		echo "$(CYAN)Migrating $$repo...$(NC)"; \
		make migrate-repo REPO=$$repo; \
	done
	@echo "$(GREEN)Done migrating all repositories.$(NC)"

validate-structure: ## Validate Antora structure in a repository (usage: make validate-structure REPO=specifications-BASE)
	@if [ -z "$(REPO)" ]; then \
		echo "$(RED)Error: REPO variable not set. Usage: make validate-structure REPO=specifications-BASE$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Validating Antora structure in $(REPO)...$(NC)"
	@./scripts/validate-structure.sh $(REPOS_DIR)/$(REPO)

validate-all: ## Validate Antora structure in all repositories
	@echo "$(GREEN)Validating all repositories...$(NC)"
	@for repo in $(SPECS_REPOS); do \
		echo "$(CYAN)Validating $$repo...$(NC)"; \
		make validate-structure REPO=$$repo; \
	done

##@ Build Operations

install-deps: ## Install Node.js dependencies
	@echo "$(GREEN)Installing Node.js dependencies...$(NC)"
	npm install

build: ## Build the full site using production playbook
	@echo "$(GREEN)Building openEHR specifications site...$(NC)"
	npx antora antora-playbook.yml
	@echo "$(GREEN)Build complete! Site generated in $(BUILD_DIR)/site$(NC)"

build-local: ## Build site using local repositories
	@echo "$(GREEN)Building site from local repositories...$(NC)"
	@if [ ! -d "$(REPOS_DIR)" ]; then \
		echo "$(RED)Error: $(REPOS_DIR) directory not found. Run 'make clone-repos' first.$(NC)"; \
		exit 1; \
	fi
	npx antora antora-playbook-local.yml
	@echo "$(GREEN)Build complete! Site generated in $(BUILD_DIR)/site$(NC)"

build-docker: docker-up ## Build site using Docker
	@echo "$(GREEN)Building site using Docker...$(NC)"
	docker-compose exec antora npx antora antora-playbook.yml
	@echo "$(GREEN)Build complete!$(NC)"

clean: ## Clean build artifacts and cache
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf $(BUILD_DIR)
	rm -rf .cache
	@echo "$(GREEN)Clean complete.$(NC)"

clean-all: clean ## Clean everything including cloned repos
	@echo "$(RED)Cleaning everything including cloned repositories...$(NC)"
	rm -rf $(REPOS_DIR)
	@echo "$(GREEN)Clean complete.$(NC)"

##@ Preview


preview: ## Start local HTTP server to preview built site
	@if [ ! -d "$(BUILD_DIR)/site" ]; then \
		echo "$(RED)Error: Build directory not found. Run 'make build' or 'make build-local' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Starting preview server at http://localhost:8080$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@cd $(BUILD_DIR)/site && python3 -m http.server 8080

preview-docker: docker-up build-docker ## Build and preview using Docker
	@echo "$(GREEN)Site is available at http://localhost:8080$(NC)"
	@echo "$(YELLOW)Preview server is running in Docker. Use 'make docker-down' to stop.$(NC)"


migrate-spec: ## Run full migration, build, and preview workflow
	@echo "$(GREEN)Running full migration workflow...$(NC)"
	@make migrate-all
	@echo "$(GREEN)Migration completed. Building site...$(NC)"
	@make build-local
	@echo "$(GREEN)Build completed. Starting preview server...$(NC)"
	@make preview


##@ Development Workflow

dev-setup: docker-build clone-repos ## Initial setup for development
	@echo "$(GREEN)Development environment setup complete!$(NC)"
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. Run 'make create-all-branches' to create release branches from tags"
	@echo "  2. Run 'make migrate-all' to migrate repositories to Antora structure"
	@echo "  3. Run 'make build-local' to build the site"
	@echo "  4. Run 'make preview' to preview the site"

dev-rebuild: clean build-local preview ## Clean, rebuild, and preview (for development)

##@ CI/CD

ci-build: install-deps build ## CI build target
	@echo "$(GREEN)CI build complete$(NC)"

##@ Information

list-repos: ## List all specification repositories
	@echo "$(CYAN)OpenEHR Specification Repositories:$(NC)"
	@for repo in $(SPECS_REPOS); do \
		echo "  - $$repo"; \
	done

check-deps: ## Check if required dependencies are installed
	@echo "$(CYAN)Checking dependencies...$(NC)"
	@command -v node >/dev/null 2>&1 || { echo "$(RED)Node.js is not installed$(NC)"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "$(RED)npm is not installed$(NC)"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "$(RED)git is not installed$(NC)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(YELLOW)Docker is not installed (optional)$(NC)"; }
	@echo "$(GREEN)All required dependencies are installed$(NC)"

