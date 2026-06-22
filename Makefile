# Makefile for building cpuinfo without opening the Xcode GUI.
#
# This still uses Apple's command-line toolchain (xcodebuild, part of Xcode or
# the Command Line Tools) — a Cocoa app cannot be built without it because the
# build also compiles the .xib (ibtool), the asset catalog (actool), the
# embedded login helper, and performs Info.plist substitution / code signing.
# It just means you never have to launch the Xcode IDE.

PROJECT      := cpuinfo.xcodeproj
SCHEME       := cpuinfo
CONFIGURATION ?= Debug
DERIVED_DATA := build
APP          := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/cpuinfo.app
DIST         := dist/cpuinfo.zip

# Skip code signing by default so it builds on any machine / in CI.
# Override with `make build CODE_SIGNING_ALLOWED=YES` to sign.
CODE_SIGNING_ALLOWED ?= NO

XCODEBUILD := xcodebuild \
	-project $(PROJECT) \
	-scheme $(SCHEME) \
	-configuration $(CONFIGURATION) \
	-derivedDataPath $(DERIVED_DATA) \
	CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED)

.DEFAULT_GOAL := help

.PHONY: help build release test run zip clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## Build the app ($(CONFIGURATION))
	$(XCODEBUILD) build

release: ## Build the app in Release configuration
	$(MAKE) build CONFIGURATION=Release

test: ## Build and run the unit tests
	$(XCODEBUILD) test

run: build ## Build then launch the built app
	open "$(APP)"

zip: release ## Package the Release app into $(DIST)
	@mkdir -p dist
	ditto -c -k --sequesterRsrc --keepParent \
		"$(DERIVED_DATA)/Build/Products/Release/cpuinfo.app" "$(DIST)"
	@echo "Packaged -> $(DIST)"

clean: ## Remove build artifacts
	$(XCODEBUILD) clean
	rm -rf $(DERIVED_DATA)
