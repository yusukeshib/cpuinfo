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
ARCHIVE      := $(DERIVED_DATA)/cpuinfo.xcarchive
EXPORT_DIR   := $(DERIVED_DATA)/export

# --- Mac App Store distribution ---
# Needs an App Store Connect API key (.p8). Create one at
#   App Store Connect -> Users and Access -> Integrations -> App Store Connect API
# then pass its 3 coordinates when invoking, e.g.:
#   make appstore \
#     ASC_KEY_ID=ABC123XYZ \
#     ASC_ISSUER_ID=11111111-2222-3333-4444-555555555555 \
#     ASC_KEY_PATH=$HOME/.appstoreconnect/private_keys/AuthKey_ABC123XYZ.p8
ASC_KEY_ID    ?=
ASC_ISSUER_ID ?=
ASC_KEY_PATH  ?=
ASC_AUTH := \
	-authenticationKeyID $(ASC_KEY_ID) \
	-authenticationKeyIssuerID $(ASC_ISSUER_ID) \
	-authenticationKeyPath $(ASC_KEY_PATH) \
	-allowProvisioningUpdates

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

.PHONY: help build release test run zip clean archive appstore _require-asc

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

_require-asc:
	@test -n "$(ASC_KEY_ID)"    || { echo "error: set ASC_KEY_ID (see Makefile header)";    exit 1; }
	@test -n "$(ASC_ISSUER_ID)" || { echo "error: set ASC_ISSUER_ID (see Makefile header)"; exit 1; }
	@test -f "$(ASC_KEY_PATH)"  || { echo "error: ASC_KEY_PATH not found: $(ASC_KEY_PATH)";    exit 1; }

archive: _require-asc ## Archive the app for distribution (Release)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED_DATA) -archivePath $(ARCHIVE) \
		$(ASC_AUTH) archive

appstore: archive ## Archive + upload to App Store Connect (needs ASC_* vars)
	xcodebuild -exportArchive -archivePath $(ARCHIVE) \
		-exportOptionsPlist ExportOptions.plist -exportPath $(EXPORT_DIR) \
		$(ASC_AUTH)
	@echo "Uploaded to App Store Connect -> check processing in the TestFlight/App Store tab."
