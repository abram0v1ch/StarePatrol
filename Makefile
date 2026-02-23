APP_NAME = StarePatrol
BUNDLE_ID = com.vasyl.StarePatrol
BUILD_DIR = build
BUNDLE_DIR_NAME = StarePatrolApp.app
APP_DIR = $(BUILD_DIR)/$(BUNDLE_DIR_NAME)
MACOS_DIR = $(APP_DIR)/Contents/MacOS
RESOURCES_DIR = $(APP_DIR)/Contents/Resources
SWIFT_FILES = $(wildcard Sources/*.swift)
SWIFT_COMPILER = swiftc
SWIFT_FLAGS = -O -module-cache-path /tmp/swift-module-cache -Xcc -fmodules-cache-path=/tmp/clang-module-cache -parse-as-library -target arm64-apple-macosx14.0

all: clean build

build:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	
	# Compile Swift files
	$(SWIFT_COMPILER) $(SWIFT_FLAGS) $(SWIFT_FILES) -o $(MACOS_DIR)/StarePatrol
	
	# Copy Info.plist
	cp Info.plist $(APP_DIR)/Contents/Info.plist
	
	# Copy AppIcon directly
	cp icon.png $(RESOURCES_DIR)/AppIcon.png
	
	# Copy assets directly if any (we will use system SF symbols mostly initially)
	
	# Sign the app to avoid security warnings when running locally
	codesign --force --deep --sign - $(APP_DIR)
	
	@echo "Build complete. Run with: open $(APP_DIR)"

clean:
	rm -rf $(APP_DIR)

.PHONY: all build clean
