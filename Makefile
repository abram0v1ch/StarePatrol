APP_NAME      = StarePatrol
BUNDLE_ID     = com.vasyl.StarePatrol
BUILD_DIR     = app
APP_DIR       = /tmp/StarePatrol-build/$(APP_NAME).app
MACOS_DIR     = $(APP_DIR)/Contents/MacOS
RESOURCES_DIR = $(APP_DIR)/Contents/Resources
SWIFT_FILES   = $(wildcard Sources/*.swift)
SWIFT_FLAGS   = -O -module-cache-path /tmp/swift-module-cache \
                -Xcc -fmodules-cache-path=/tmp/clang-module-cache \
                -parse-as-library -target arm64-apple-macosx14.0

all: test build

# ── Tests ──────────────────────────────────────────────────────────────────
test:
	@echo "🧪 Running tests..."
	TMPDIR=/tmp/xcrun_cache swift test
	@echo "✅ All tests passed."

# ── Build ──────────────────────────────────────────────────────────────────
build:
	@# 1. Quit any running instance
	-killall $(APP_NAME) 2>/dev/null; sleep 0.5
	@# 2. Compile into /tmp (no provenance lock)
	mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	swiftc $(SWIFT_FLAGS) $(SWIFT_FILES) -o $(MACOS_DIR)/$(APP_NAME)
	cp Info.plist $(APP_DIR)/Contents/Info.plist
	cp icon.png   $(RESOURCES_DIR)/AppIcon.png
	codesign --force --deep --sign - $(APP_DIR)
	@echo "✓ $(APP_DIR)"

run: build
	open $(APP_DIR)

# ── Setup ──────────────────────────────────────────────────────────────────
# Run once after cloning to install the pre-commit hook
setup:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@echo "✓ Git hooks installed. Tests will run before every commit."

clean:
	-killall $(APP_NAME) 2>/dev/null; sleep 0.5
	rm -rf $(APP_DIR)

.PHONY: all test build run setup clean
