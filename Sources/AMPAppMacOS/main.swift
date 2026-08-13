import Cocoa
import SwiftUI
import AMPShared

PlatformBridge.registerFloatingTimer { timer in
    FloatingTimerWindow.shared.attach(timer: timer)
}
PlatformBridge.registerAttention {
    NSApp.requestUserAttention(.informationalRequest)
}

final class AMPAppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()

        let hosting = NSHostingView(rootView: MainView())

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        w.title = "AMP"
        w.setContentSize(NSSize(width: 620, height: 760))
        w.contentView = hosting
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        window = w
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

private func installMainMenu() {
    let mainMenu = NSMenu()

    let appMenu = NSMenu()
    appMenu.addItem(NSMenuItem(title: "About AMP",
                               action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                               keyEquivalent: ""))
    appMenu.addItem(.separator())
    appMenu.addItem(NSMenuItem(title: "Hide AMP",
                               action: #selector(NSApplication.hide(_:)),
                               keyEquivalent: "h"))
    appMenu.addItem(NSMenuItem(title: "Hide Others",
                               action: #selector(NSApplication.hideOtherApplications(_:)),
                               keyEquivalent: ""))
    appMenu.addItem(NSMenuItem(title: "Show All",
                               action: #selector(NSApplication.unhideAllApplications(_:)),
                               keyEquivalent: ""))
    appMenu.addItem(.separator())
    appMenu.addItem(NSMenuItem(title: "Quit AMP",
                               action: #selector(NSApplication.terminate(_:)),
                               keyEquivalent: "q"))
    mainMenu.addItem(NSMenuItem(title: "Apple", action: nil, keyEquivalent: ""))
    mainMenu.item(at: 0)!.submenu = appMenu

    let fileMenu = NSMenu()
    fileMenu.addItem(NSMenuItem(title: "Close Window",
                                action: #selector(NSWindow.performClose(_:)),
                                keyEquivalent: "w"))
    fileMenu.addItem(.separator())
    fileMenu.addItem(NSMenuItem(title: "Quit AMP",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
    mainMenu.addItem(NSMenuItem(title: "File", action: nil, keyEquivalent: ""))
    mainMenu.item(at: 1)!.submenu = fileMenu

    let windowMenu = NSMenu()
    windowMenu.addItem(NSMenuItem(title: "Minimize",
                                  action: #selector(NSWindow.performMiniaturize(_:)),
                                  keyEquivalent: "m"))
    mainMenu.addItem(NSMenuItem(title: "Window", action: nil, keyEquivalent: ""))
    mainMenu.item(at: 2)!.submenu = windowMenu

    NSApp.mainMenu = mainMenu
}

// Entry point (top-level code)
let delegate = AMPAppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = delegate
app.activate(ignoringOtherApps: true)
app.run()
