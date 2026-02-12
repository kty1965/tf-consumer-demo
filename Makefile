MAKEFLAGS += --warn-undefined-variables
.SILENT:
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.SUFFIXES:

# ============================================
# 프로젝트 설정
# ============================================
PROJECT := tf-consumer-demo
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v0.0.0")

# ============================================
# 공유 모듈 버전 설정 (모듈별 독립)
# ============================================
TERRAFORM_MODULE_VERSION := v1.3.0
SHARED_MODULE_VERSION := v1.3.0

# 모듈별 태그 (수정된 형식: terraform-v1.3.0)
TERRAFORM_TAG := terraform-$(TERRAFORM_MODULE_VERSION)
SHARED_TAG := shared-$(SHARED_MODULE_VERSION)

TERRAFORM_URL := https://github.com/kty1965/makefile-modules/releases/download/$(TERRAFORM_TAG)
SHARED_URL := https://github.com/kty1965/makefile-modules/releases/download/$(SHARED_TAG)

# ============================================
# 모드 선택: download 또는 vendor
# ============================================
# USE_VENDOR=1 make build  # Vendoring 모드
# make build               # Auto-download 모드 (기본)
USE_VENDOR ?= 0

ifeq ($(USE_VENDOR),1)
  MODULES_DIR := vendor/make
  $(info 📦 Using vendored modules from $(MODULES_DIR))
else
  MODULES_DIR := make
  $(info 🌐 Using auto-download mode)
endif

# ============================================
# 자동 다운로드 패턴 (모듈별)
# ============================================
make/terraform.mk:
	@mkdir -p make
	@echo "📦 Downloading terraform.mk $(TERRAFORM_MODULE_VERSION)..."
	@curl -fsSL $(TERRAFORM_URL)/terraform.mk -o $@
	@curl -fsSL $(TERRAFORM_URL)/checksums.txt -o make/terraform-checksums.txt
	@cd make && grep "terraform.mk" terraform-checksums.txt | sha256sum -c -
	@echo "✅ Verified terraform.mk"

make/shared.mk:
	@mkdir -p make
	@echo "📦 Downloading shared.mk $(SHARED_MODULE_VERSION)..."
	@curl -fsSL $(SHARED_URL)/shared.mk -o $@
	@curl -fsSL $(SHARED_URL)/checksums.txt -o make/shared-checksums.txt
	@cd make && grep "shared.mk" shared-checksums.txt | sha256sum -c -
	@echo "✅ Verified shared.mk"

# ============================================
# Vendoring 패턴 (모듈별)
# ============================================
.PHONY: vendor
vendor: ## Download modules to vendor/ directory (commit to Git)
	@echo "📦 Vendoring modules..."
	@echo "  terraform.mk: $(TERRAFORM_MODULE_VERSION)"
	@echo "  shared.mk: $(SHARED_MODULE_VERSION)"
	@mkdir -p vendor/make
	@echo "  Downloading terraform.mk..."
	@curl -fsSL $(TERRAFORM_URL)/terraform.mk -o vendor/make/terraform.mk
	@curl -fsSL $(TERRAFORM_URL)/checksums.txt -o vendor/make/terraform-checksums.txt
	@echo "  Downloading shared.mk..."
	@curl -fsSL $(SHARED_URL)/shared.mk -o vendor/make/shared.mk
	@curl -fsSL $(SHARED_URL)/checksums.txt -o vendor/make/shared-checksums.txt
	@cd vendor/make && grep "terraform.mk" terraform-checksums.txt | sha256sum -c -
	@cd vendor/make && grep "shared.mk" shared-checksums.txt | sha256sum -c -
	@echo "✅ All modules vendored and verified"
	@echo ""
	@echo "Next steps:"
	@echo "  git add vendor/make"
	@echo "  git commit -m 'chore: vendor terraform.mk $(TERRAFORM_MODULE_VERSION), shared.mk $(SHARED_MODULE_VERSION)'"

# ============================================
# 모듈 관리
# ============================================
.PHONY: modules/clean
modules/clean: ## Clean downloaded modules
	@echo "🧹 Cleaning downloaded modules..."
	@rm -rf make/*.mk make/*-checksums.txt
	@echo "✅ Cleaned"

.PHONY: modules/update
modules/update: modules/clean ## Update modules to latest version
	@echo "🔄 Updating modules..."
	@$(MAKE) $(MODULES_DIR)/terraform.mk
	@$(MAKE) $(MODULES_DIR)/shared.mk
	@echo "✅ Modules updated"

.PHONY: modules/version
modules/version: ## Show current module versions
	@echo "Module versions:"
	@echo "  terraform.mk: $(TERRAFORM_MODULE_VERSION) (tag: $(TERRAFORM_TAG))"
	@echo "  shared.mk: $(SHARED_MODULE_VERSION) (tag: $(SHARED_TAG))"
	@echo ""
	@echo "Using vendored: $(USE_VENDOR)"
	@echo "Modules directory: $(MODULES_DIR)"

# ============================================
# 모듈 포함
# ============================================
include $(MODULES_DIR)/shared.mk
include $(MODULES_DIR)/terraform.mk

# ============================================
# Terraform 설정 오버라이드 (local backend for demo)
# ============================================
unexport TF_CLI_ARGS_init
unexport TF_CLI_ARGS_plan
unexport TF_CLI_ARGS_apply
unexport TF_CLI_ARGS_destroy

# ============================================
# 프로젝트 고유 타겟 (terraform.mk 활용)
# ============================================
.PHONY: build
build: tf/validate tf/fmt ## Validate and format

.PHONY: deploy
deploy: tf/plan ## Plan deployment
	@echo ""
	@read -p "Apply changes? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
	  $(MAKE) tf/apply; \
	fi

# ============================================
# Help
# ============================================
.PHONY: help
help: ## Show this help
	@echo "$(PROJECT) - $(VERSION)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Project Targets:"
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' Makefile | \
	  grep -v '^tf/' | \
	  grep -v '^modules/' | \
	  sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Terraform Targets (from terraform.mk):"
	@grep -E '^\.PHONY: (tf/.*)$$' $(MODULES_DIR)/terraform.mk | \
	  sed 's/.PHONY: //' | \
	  while read target; do \
	    desc=$$(grep "^$$target:.*## " $(MODULES_DIR)/terraform.mk | sed 's/.*## //'); \
	    printf "  \033[36m%-25s\033[0m %s\n" "$$target" "$$desc"; \
	  done | sort
	@echo ""
	@echo "Module Management:"
	@grep -E '^modules/[a-zA-Z_-]+:.*?## .*$$' Makefile | \
	  sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Module Versions:"
	@echo "  terraform.mk: $(TERRAFORM_MODULE_VERSION)"
	@echo "  shared.mk: $(SHARED_MODULE_VERSION)"
