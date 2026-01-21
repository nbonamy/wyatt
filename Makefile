.PHONY: build install uninstall clean

APP_NAME = Wyatt
BUNDLE_ID = com.nbonamy.wyatt
VERSION = 1.0.0
INSTALL_DIR = /Applications
APP_BUNDLE = $(APP_NAME).app

build:
	swift build -c release
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp .build/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(APP_BUNDLE)/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '<dict>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleExecutable</key><string>$(APP_NAME)</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleIdentifier</key><string>$(BUNDLE_ID)</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleName</key><string>$(APP_NAME)</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleVersion</key><string>$(VERSION)</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleShortVersionString</key><string>$(VERSION)</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundlePackageType</key><string>APPL</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>LSMinimumSystemVersion</key><string>13.0</string>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '    <key>LSUIElement</key><true/>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '</dict>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo '</plist>' >> $(APP_BUNDLE)/Contents/Info.plist
	@echo "Built $(APP_BUNDLE)"

install: build
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	@echo "Uninstalled $(APP_BUNDLE)"

clean:
	rm -rf .build $(APP_BUNDLE)
