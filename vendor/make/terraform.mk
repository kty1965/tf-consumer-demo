# modules/terraform/terraform.mk
# Terraform 워크플로우 재사용 모듈
# Version: 1.0.0

ifndef TERRAFORM_MK
TERRAFORM_MK := 1

# ============================================
# Terraform 변수
# ============================================
TF ?= terraform
TF_ENV ?= dev
TF_ROOT_MODULE_DIR ?= ./src
TF_CONFIG_DIR ?= ./config
TF_ENV_DIR := $(TF_CONFIG_DIR)/$(TF_ENV)
TF_DATA_DIR := $(TF_ENV_DIR)/.terraform
TF_BACKEND_CONFIG := $(TF_ENV_DIR)/backend.conf
TF_VARS_FILE := $(TF_ENV_DIR)/terraform.tfvars

# ============================================
# Terraform 환경변수
# ============================================
export TF_DATA_DIR
export TF_CLI_ARGS_init=-backend-config=$(TF_BACKEND_CONFIG)
export TF_CLI_ARGS_plan=-input=false -var-file=$(TF_VARS_FILE)
export TF_CLI_ARGS_apply=-var-file=$(TF_VARS_FILE)
export TF_CLI_ARGS_destroy=-var-file=$(TF_VARS_FILE)

# ============================================
# 색상 출력
# ============================================
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_BLUE := \033[36m
COLOR_YELLOW := \033[33m

define tf_log_info
	@echo "$(COLOR_BLUE)ℹ️  $(1)$(COLOR_RESET)"
endef

define tf_log_success
	@echo "$(COLOR_GREEN)✅ $(1)$(COLOR_RESET)"
endef

define tf_log_warn
	@echo "$(COLOR_YELLOW)⚠️  $(1)$(COLOR_RESET)"
endef

# ============================================
# Terraform 초기화
# ============================================
.PHONY: tf/init
tf/init: ## Initialize Terraform
	$(call tf_log_info,Initializing Terraform for environment: $(TF_ENV))
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) init
	$(call tf_log_success,Terraform initialized)

.PHONY: tf/init-upgrade
tf/init-upgrade: ## Initialize with module upgrade
	$(call tf_log_info,Initializing with upgrade...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) init -upgrade
	$(call tf_log_success,Modules upgraded)

.PHONY: tf/init-reconfigure
tf/init-reconfigure: ## Reconfigure backend
	$(call tf_log_info,Reconfiguring backend...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) init -reconfigure
	$(call tf_log_success,Backend reconfigured)

# ============================================
# Terraform 검증 및 포맷팅
# ============================================
.PHONY: tf/validate
tf/validate: ## Validate Terraform configuration
	$(call tf_log_info,Validating configuration...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) validate
	$(call tf_log_success,Configuration valid)

.PHONY: tf/fmt
tf/fmt: ## Format Terraform files
	$(call tf_log_info,Formatting files...)
	$(TF) fmt -recursive -diff
	$(call tf_log_success,Files formatted)

.PHONY: tf/fmt-check
tf/fmt-check: ## Check if files are formatted
	$(call tf_log_info,Checking format...)
	$(TF) fmt -recursive -check -diff

# ============================================
# Terraform 플랜 및 적용
# ============================================
.PHONY: tf/plan
tf/plan: ## Generate execution plan
	$(call tf_log_info,Generating plan for $(TF_ENV)...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) plan

.PHONY: tf/apply
tf/apply: ## Apply Terraform changes
	$(call tf_log_warn,Applying changes to $(TF_ENV)...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) apply

.PHONY: tf/apply-auto
tf/apply-auto: ## Apply changes without confirmation
	$(call tf_log_warn,Auto-applying changes to $(TF_ENV)...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) apply -auto-approve

# ============================================
# Terraform 상태 관리
# ============================================
.PHONY: tf/state-list
tf/state-list: ## List resources in state
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) state list

.PHONY: tf/output
tf/output: ## Show outputs
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) output

.PHONY: tf/refresh
tf/refresh: ## Refresh state
	$(call tf_log_info,Refreshing state...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) refresh

# ============================================
# Terraform 파괴
# ============================================
.PHONY: tf/destroy
tf/destroy: ## Destroy Terraform resources
	$(call tf_log_warn,Destroying resources in $(TF_ENV)...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) destroy

.PHONY: tf/destroy-auto
tf/destroy-auto: ## Destroy without confirmation
	$(call tf_log_warn,Auto-destroying resources in $(TF_ENV)...)
	$(TF) -chdir=$(TF_ROOT_MODULE_DIR) destroy -auto-approve

# ============================================
# 헬프
# ============================================
.PHONY: tf/help
tf/help: ## Show Terraform module help
	@echo "Terraform Module Commands:"
	@echo ""
	@grep -E '^tf/[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment: $(TF_ENV)"
	@echo "Root module: $(TF_ROOT_MODULE_DIR)"
	@echo "Config dir: $(TF_ENV_DIR)"

endif
