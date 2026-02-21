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
TERRAFORM_MODULE_VERSION := v1.3.3
SHARED_MODULE_VERSION := v1.4.2

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
else
  MODULES_DIR := make
endif

# ============================================
# 자동 다운로드 패턴 (모듈별)
# ============================================
make/terraform.mk:
	@mkdir -p make
	@echo "📦 Downloading terraform.mk $(TERRAFORM_MODULE_VERSION)..."
	@curl -fsSL $(TERRAFORM_URL)/terraform.mk -o $@
	@curl -fsSL $(TERRAFORM_URL)/checksums.txt -o make/terraform-checksums.txt
	@expected=$$(grep "terraform.mk" make/terraform-checksums.txt | awk '{print $$1}'); \
	 actual=$$(sha256sum $@ | awk '{print $$1}'); \
	 if [ "$$expected" != "$$actual" ]; then \
	   echo "❌ Checksum mismatch for terraform.mk"; \
	   echo "  expected: $$expected"; \
	   echo "  actual:   $$actual"; \
	   rm -f $@; \
	   exit 1; \
	 fi
	@echo "✅ Verified terraform.mk"

make/shared.mk:
	@mkdir -p make
	@echo "📦 Downloading shared.mk $(SHARED_MODULE_VERSION)..."
	@curl -fsSL $(SHARED_URL)/shared.mk -o $@
	@curl -fsSL $(SHARED_URL)/checksums.txt -o make/shared-checksums.txt
	@expected=$$(grep "shared.mk" make/shared-checksums.txt | awk '{print $$1}'); \
	 actual=$$(sha256sum $@ | awk '{print $$1}'); \
	 if [ "$$expected" != "$$actual" ]; then \
	   echo "❌ Checksum mismatch for shared.mk"; \
	   echo "  expected: $$expected"; \
	   echo "  actual:   $$actual"; \
	   rm -f $@; \
	   exit 1; \
	 fi
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
	@expected=$$(grep "terraform.mk" vendor/make/terraform-checksums.txt | awk '{print $$1}'); \
	 actual=$$(sha256sum vendor/make/terraform.mk | awk '{print $$1}'); \
	 if [ "$$expected" != "$$actual" ]; then echo "❌ Checksum mismatch for terraform.mk"; exit 1; fi
	@expected=$$(grep "shared.mk" vendor/make/shared-checksums.txt | awk '{print $$1}'); \
	 actual=$$(sha256sum vendor/make/shared.mk | awk '{print $$1}'); \
	 if [ "$$expected" != "$$actual" ]; then echo "❌ Checksum mismatch for shared.mk"; exit 1; fi
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
	@$(MAKE) $(MODULES_DIR)/terraform.mk $(MODULES_DIR)/shared.mk
	@echo "✅ Modules updated"

.PHONY: modules/version
modules/version: ## Show current module versions
	@echo "Module versions:"
	@echo "  terraform.mk: $(TERRAFORM_MODULE_VERSION) (tag: $(TERRAFORM_TAG))"
	@echo "  shared.mk: $(SHARED_MODULE_VERSION) (tag: $(SHARED_TAG))"
	@echo ""
	@echo "Using vendored: $(USE_VENDOR)"
	@echo "Modules directory: $(MODULES_DIR)"
	@if [ "$(USE_VENDOR)" = "1" ]; then \
	  echo "Mode: 📦 vendored"; \
	else \
	  echo "Mode: 🌐 auto-download"; \
	fi

# ============================================
# 모듈 포함
# ============================================
-include $(MODULES_DIR)/shared.mk
-include $(MODULES_DIR)/terraform.mk

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
	@$(MAKE) -s tf/help
	@echo ""
	@echo "Module Management:"
	@grep -E '^modules/[a-zA-Z_-]+:.*?## .*$$' Makefile | \
	  sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Module Versions:"
	@echo "  terraform.mk: $(TERRAFORM_MODULE_VERSION)"
	@echo "  shared.mk: $(SHARED_MODULE_VERSION)"
