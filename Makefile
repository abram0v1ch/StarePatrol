APP_NAME = StarePolice
BUNDLE_ID = com.vasyl.StarePolice
APP_DIR = $(APP_NAME).app
MACOS_DIR = $(APP_DIR)/Contents/MacOS
RESOURCES_DIR = $(APP_DIR)/Contents/Resources
SWIFT_FILES = $(wildcard Sources/*.swift)
SWIFT_COMPILER = swiftc
SWIFT_FLAGS = -O -module-cache-path /tmp/module-cache -parse-as-library -target arm64-apple-macosx14.0

all: clean build

build:
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	
	# Compile Swift files
	$(SWIFT_COMPILER) $(SWIFT_FLAGS) $(SWIFT_FILES) -o $(MACOS_DIR)/$(APP_NAME)
	
	# Copy Info.plist
	cp Info.plist $(APP_DIR)/Contents/Info.plist
	
	# Copy assets directly if any (we will use system SF symbols mostly initially)
	
	# Sign the app to avoid security warnings when running locally
	codesign --force --deep --sign - $(APP_DIR)
	
	@echo "Build complete. Run with: open $(APP_DIR)"

clean:
	rm -rf $(APP_DIR)

.PHONY: all build clean
