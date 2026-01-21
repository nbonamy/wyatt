import SwiftUI
import AppKit
import ApplicationServices

@main
struct WyattApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var hotKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermissions()
        setupStatusItem()
        setupGlobalHotKey()
    }

    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("Wyatt needs Accessibility permissions to move windows.")
        }
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lasso", accessibilityDescription: "Wyatt")
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            WindowManager.roundup()
        }
    }

    func showMenu() {
        let menu = NSMenu()
        let roundupItem = NSMenuItem(title: "Round 'em up!", action: #selector(roundup), keyEquivalent: "r")
        roundupItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(roundupItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Wyatt", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func roundup() {
        WindowManager.roundup()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func setupGlobalHotKey() {
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // ⌘⌥R
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 15 {
                WindowManager.roundup()
            }
        }
    }
}

struct WindowManager {
    static func roundup() {
        guard let mainScreen = NSScreen.screens.first else {
            print("No screens found")
            return
        }

        let mainFrame = mainScreen.visibleFrame

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            print("Could not get window list")
            return
        }

        for windowInfo in windowList {
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let windowX = boundsDict["X"],
                  let windowY = boundsDict["Y"],
                  let windowWidth = boundsDict["Width"],
                  let windowHeight = boundsDict["Height"],
                  let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer == 0 else {
                continue
            }

            // Check if window is outside the main screen
            let windowFrame = CGRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
            let mainScreenBounds = CGRect(
                x: mainScreen.frame.origin.x,
                y: mainScreen.frame.origin.y,
                width: mainScreen.frame.width,
                height: mainScreen.frame.height
            )

            if !mainScreenBounds.contains(windowFrame.origin) {
                moveWindow(pid: ownerPID, from: windowFrame, to: mainFrame)
            }
        }

        print("🤠 Wyatt rounded up all the windows!")
    }

    static func moveWindow(pid: pid_t, from windowFrame: CGRect, to targetFrame: NSRect) {
        let app = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return
        }

        for window in windows {
            var positionRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)

            if let positionRef = positionRef, let sizeRef = sizeRef {
                var currentPosition = CGPoint.zero
                var currentSize = CGSize.zero
                AXValueGetValue(positionRef as! AXValue, .cgPoint, &currentPosition)
                AXValueGetValue(sizeRef as! AXValue, .cgSize, &currentSize)

                // Check if this is approximately the window we're looking for
                if abs(currentPosition.x - windowFrame.origin.x) < 10 &&
                   abs(currentPosition.y - windowFrame.origin.y) < 10 {

                    // Keep same relative position but clamp to screen bounds
                    var newX = currentPosition.x
                    var newY = currentPosition.y

                    // Clamp X: ensure window fits horizontally
                    let maxX = targetFrame.origin.x + targetFrame.width - currentSize.width
                    newX = max(targetFrame.origin.x, min(newX, maxX))

                    // Clamp Y: ensure window fits vertically (account for menu bar)
                    let minY = targetFrame.origin.y
                    let maxY = targetFrame.origin.y + targetFrame.height - currentSize.height
                    newY = max(minY, min(newY, maxY))

                    var newPosition = CGPoint(x: newX, y: newY)

                    if let newPositionValue = AXValueCreate(.cgPoint, &newPosition) {
                        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPositionValue)
                    }
                }
            }
        }
    }
}
