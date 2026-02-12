# modules/shared/shared.mk
# 공통 유틸리티 모듈
# Version: 1.0.0

ifndef SHARED_MK
SHARED_MK := 1

# ============================================
# 공통 변수
# ============================================
BUILD_DIR ?= ./build
DIST_DIR ?= ./dist

# ============================================
# 색상 정의
# ============================================
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_BLUE := \033[36m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m

# ============================================
# 공통 헬퍼 함수
# ============================================
define log_info
	@echo "$(COLOR_BLUE)ℹ️  $(1)$(COLOR_RESET)"
endef

define log_success
	@echo "$(COLOR_GREEN)✅ $(1)$(COLOR_RESET)"
endef

define log_warn
	@echo "$(COLOR_YELLOW)⚠️  $(1)$(COLOR_RESET)"
endef

define log_error
	@echo "$(COLOR_RED)❌ $(1)$(COLOR_RESET)"
endef

# ============================================
# 공통 타겟
# ============================================
.PHONY: clean
clean:: ## Clean build artifacts
	$(call log_info,Cleaning build artifacts...)
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	$(call log_success,Clean complete)

.PHONY: version
version: ## Show project version
	@echo "Project: $(PROJECT)"
	@echo "Version: $(VERSION)"

endif
