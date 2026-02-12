# Terraform Consumer Demo

Demo project using modularized Makefile from [makefile-modules](https://github.com/kty1965/makefile-modules).

## 🚀 Quick Start

### Using Auto-download Mode (Default)

```bash
# Modules are downloaded automatically on first run
make help

# Available targets
make modules/version
```

### Using Vendoring Mode

```bash
# Download and commit modules
make vendor
git add vendor/make
git commit -m "chore: vendor terraform v1.1.0, shared v1.1.0"

# Use vendored modules
USE_VENDOR=1 make help
```

## 📋 Available Commands

### General
- `make help` - Show all available targets
- `make build` - Validate and format
- `make deploy` - Plan and apply (with confirmation)

### Terraform
- `make tf/init` - Initialize Terraform
- `make tf/plan` - Generate execution plan
- `make tf/apply` - Apply changes
- `make tf/validate` - Validate configuration
- `make tf/fmt` - Format Terraform files

### Module Management
- `make modules/version` - Show current module versions
- `make modules/update` - Update to latest versions
- `make modules/clean` - Clean downloaded modules
- `make vendor` - Download modules for vendoring

## 🔧 Configuration

Edit module versions in `Makefile`:

```makefile
TERRAFORM_MODULE_VERSION := v1.1.0
SHARED_MODULE_VERSION := v1.1.0
```

## 🔄 Switching Between Modes

### Auto-download → Vendoring
```bash
make vendor
git add vendor/make
git commit -m "chore: switch to vendoring mode"
# Set USE_VENDOR=1 in Makefile or use env var
```

### Vendoring → Auto-download
```bash
rm -rf vendor/make
git add vendor/make
git commit -m "chore: switch to auto-download mode"
# Set USE_VENDOR=0
```

## 📦 Module Versions

| Module | Version | Release |
|--------|---------|---------|
| terraform.mk | v1.1.0 | [terraform-vv1.1.0](https://github.com/kty1965/makefile-modules/releases/tag/terraform-vv1.1.0) |
| shared.mk | v1.1.0 | [shared-vv1.1.0](https://github.com/kty1965/makefile-modules/releases/tag/shared-vv1.1.0) |

## 📝 Example: Run Terraform

```bash
# Initialize (downloads modules automatically)
make tf/init

# Validate and format
make build

# Plan changes
make tf/plan

# Check what would be created
make tf/output
```
