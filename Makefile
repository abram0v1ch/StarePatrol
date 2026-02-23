APP_NAME      = StarePatrol
BUNDLE_ID     = com.vasyl.StarePatrol
# macOS sets com.apple.provenance on any directory an app is launched from,
# making subsequent .app creation there fail.  We build and run from /tmp.
APP_DIR       = /tmp/StarePatrol-build/$(APP_NAME).app
MACOS_DIR     = $(APP_DIR)/Contents/MacOS
RESOURCES_DIR = $(APP_DIR)/Contents/Resources
SWIFT_FILES   = $(wildcard Sources/*.swift)
SWIFT_FLAGS   = -O -module-cache-path /tmp/swift-module-cache \
                -Xcc -fmodules-cache-path=/tmp/clang-module-cache \
                -parse-as-library -target arm64-apple-macosx14.0

all: build

build:
	@# 1. Quit any running instance
	-killall $(APP_NAME) 2>/dev/null; sleep 0.5
	@# 2. Compile directly in /tmp (no provenance lock)
	mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	swiftc $(SWIFT_FLAGS) $(SWIFT_FILES) -o $(MACOS_DIR)/$(APP_NAME)
	cp Info.plist $(APP_DIR)/Contents/Info.plist
	cp icon.png   $(RESOURCES_DIR)/AppIcon.png
	codesign --force --deep --sign - $(APP_DIR)
	@echo "✓ Build complete → $(APP_DIR)"
	@echo "  Run with: open $(APP_DIR)"

run: build
	open $(APP_DIR)

clean:
	-killall $(APP_NAME) 2>/dev/null; sleep 0.5
	rm -rf $(APP_DIR)

.PHONY: all build run clean
