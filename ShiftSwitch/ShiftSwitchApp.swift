//
//  ShiftSwitchApp.swift
//  ShiftSwitch
//
//  Created by apple on 2025/9/21.
//

import Cocoa
import Carbon
import IOKit
import SwiftUI
import os.log

// MARK: - 调试日志管理
class DebugLogger {
    static let shared = DebugLogger()
    private let logger = Logger(subsystem: "com.shiftswitch.app", category: "Debug")
    
    private init() {}
    
    func debug(_ message: String) {
        // 只在调试模式下输出debug信息
        #if DEBUG
        print("🔍 \(message)")
        #endif
    }
    
    func info(_ message: String) {
        print("ℹ️ \(message)")
    }
    
    func warning(_ message: String) {
        print("⚠️ \(message)")
    }
    
    func error(_ message: String) {
        print("❌ \(message)")
    }
    
    func success(_ message: String) {
        print("✅ \(message)")
    }
}

// MARK: - 输入法管理类
class InputSourceManager {
    static let shared = InputSourceManager()
    
    private init() {
        DebugLogger.shared.info("InputSourceManager 初始化")
        #if DEBUG
        debugAllInputSources()
        #endif
    }
    
    /// 获取当前输入法
    func getCurrentInputSource() -> TISInputSource? {
        let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
        if let source = inputSource, let id = getInputSourceID(source) {
            DebugLogger.shared.debug("当前输入法: \(id)")
        } else {
            DebugLogger.shared.error("无法获取当前输入法")
        }
        return inputSource
    }
    
    /// 获取输入法ID
    func getInputSourceID(_ inputSource: TISInputSource) -> String? {
        guard let cfID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else {
            DebugLogger.shared.error("无法获取输入法ID属性")
            return nil
        }
        let id = Unmanaged<CFString>.fromOpaque(cfID).takeUnretainedValue() as String
        return id
    }
    
    /// 获取输入法名称
    func getInputSourceName(_ inputSource: TISInputSource) -> String? {
        guard let cfName = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(cfName).takeUnretainedValue() as String
    }
    
    /// 检查输入法是否可用和可选择
    func isInputSourceAvailable(_ inputSource: TISInputSource) -> Bool {
        // 检查是否启用
        let isEnabled = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsEnabled)
        let enabled = isEnabled != nil && CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(isEnabled!).takeUnretainedValue())
        
        // 检查是否可选择
        let isSelectable = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable)
        let selectable = isSelectable != nil && CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(isSelectable!).takeUnretainedValue())
        
        return enabled && selectable
    }
    
    /// 调试所有输入法
    func debugAllInputSources() {
        DebugLogger.shared.info("=== 调试所有输入法 ===")
        let enabledSources = getEnabledInputSources()
        DebugLogger.shared.info("已启用的输入法数量: \(enabledSources.count)")
        
        for (index, source) in enabledSources.enumerated() {
            if let id = getInputSourceID(source), let name = getInputSourceName(source) {
                let category = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory)
                let categoryString = category != nil ? Unmanaged<CFString>.fromOpaque(category!).takeUnretainedValue() as String : "unknown"
                let available = isInputSourceAvailable(source)
                DebugLogger.shared.info("[\(index)] ID: \(id), 名称: \(name), 类别: \(categoryString), 可用: \(available)")
            }
        }
        DebugLogger.shared.info("=== 输入法调试结束 ===")
    }
    
    /// 获取所有已启用的输入法
    func getEnabledInputSources() -> [TISInputSource] {
        let criteria = [kTISPropertyInputSourceIsEnabled: true] as CFDictionary
        let inputSources = TISCreateInputSourceList(criteria, false)?.takeRetainedValue()
        
        guard let sources = inputSources else { 
            DebugLogger.shared.error("无法获取输入法列表")
            return [] 
        }
        
        var result: [TISInputSource] = []
        let count = CFArrayGetCount(sources)
        DebugLogger.shared.debug("系统返回 \(count) 个输入法")
        
        for i in 0..<count {
            let inputSource = CFArrayGetValueAtIndex(sources, i)
            let tisInputSource = Unmanaged<TISInputSource>.fromOpaque(inputSource!).takeUnretainedValue()
            result.append(tisInputSource)
        }
        
        return result
    }
    
    /// 切换输入法
    func toggleInputSource() -> Bool {
        guard let currentInputSource = getCurrentInputSource(),
              let currentID = getInputSourceID(currentInputSource) else {
            DebugLogger.shared.error("无法获取当前输入法")
            return false
        }
        
        let enabledSources = getEnabledInputSources()
        let keyboardSources = enabledSources.filter { source in
            guard let category = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else {
                return false
            }
            let categoryString = Unmanaged<CFString>.fromOpaque(category).takeUnretainedValue() as String
            return categoryString == kTISCategoryKeyboardInputSource as String
        }
        
        // 查找中文和英文输入法
        var chineseSource: TISInputSource?
        var englishSource: TISInputSource?
        var chineseSources: [TISInputSource] = []
        
        for source in keyboardSources {
            if let sourceID = getInputSourceID(source), let name = getInputSourceName(source) {
                let available = isInputSourceAvailable(source)
                
                // 更宽泛的中文输入法检测
                if sourceID.contains("com.apple.inputmethod") || 
                   sourceID.contains("SCIM") || 
                   sourceID.contains("Pinyin") ||
                   sourceID.contains("Wubi") ||
                   sourceID.contains("Shuangpin") ||
                   sourceID.contains("TCIM") ||
                   name.contains("中文") ||
                   name.contains("拼音") ||
                   name.contains("五笔") ||
                   name.contains("双拼") {
                    if available {
                        chineseSources.append(source)
                    }
                } else if sourceID == "com.apple.keylayout.ABC" || 
                          sourceID == "com.apple.keylayout.US" ||
                          sourceID.contains("com.apple.keylayout") {
                    if available {
                        englishSource = source
                    }
                }
            }
        }
        
        // 优先选择ITABC拼音输入法，如果不存在则选择其他中文输入法
        for source in chineseSources {
            if let sourceID = getInputSourceID(source) {
                if sourceID.contains("ITABC") || sourceID.contains("Pinyin") {
                    chineseSource = source
                    break
                }
            }
        }
        
        // 如果没有找到ITABC，选择第一个中文输入法
        if chineseSource == nil && !chineseSources.isEmpty {
            chineseSource = chineseSources.first
        }
        
        // 根据当前输入法决定切换目标
        let targetSource: TISInputSource?
        let isCurrentChinese = currentID.contains("com.apple.inputmethod") || 
                              currentID.contains("SCIM") || 
                              currentID.contains("Pinyin") ||
                              currentID.contains("Wubi") ||
                              currentID.contains("Shuangpin") ||
                              currentID.contains("TCIM")
        
        if isCurrentChinese {
            targetSource = englishSource
        } else {
            targetSource = chineseSource
        }
        
        guard let target = targetSource else {
            DebugLogger.shared.error("未找到合适的切换目标输入法")
            return false
        }
        
        let result = TISSelectInputSource(target)
        let success = result == noErr
        
        if success {
            if let targetID = getInputSourceID(target) {
                DebugLogger.shared.success("输入法切换: \(currentID) → \(targetID)")
            }
        } else {
            DebugLogger.shared.error("输入法切换失败，错误代码: \(result)")
        }
        
        return success
    }
}

// MARK: - 键盘监听管理类
class KeyboardMonitor: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Shift键状态跟踪
    private var leftShiftPressed = false
    private var rightShiftPressed = false
    private var shiftPressTime: CFAbsoluteTime = 0
    private var otherKeyPressed = false
    
    // 调试统计
    private var eventCount = 0
    private var shiftEventCount = 0
    private var capsLockEventCount = 0
    
    // 权限检查定时器
    private var permissionCheckTimer: Timer?
    private var isMonitoringActive = false
    
    init() {
        DebugLogger.shared.info("KeyboardMonitor 初始化")
        setupEventTap()
        startPermissionMonitoring()
    }
    
    deinit {
        DebugLogger.shared.info("KeyboardMonitor 销毁")
        stopPermissionMonitoring()
        stopMonitoring()
    }
    
    /// 开始权限监控
    private func startPermissionMonitoring() {
        DebugLogger.shared.info("🔄 开始权限状态监控")
        // 每2秒检查一次权限状态
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAndUpdatePermissionStatus()
        }
    }
    
    /// 停止权限监控
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        DebugLogger.shared.info("🔄 停止权限状态监控")
    }
    
    /// 检查并更新权限状态
    private func checkAndUpdatePermissionStatus() {
        let hasPermission = AXIsProcessTrusted()
        
        if hasPermission && !isMonitoringActive {
            DebugLogger.shared.success("🔓 权限已授予，重新初始化键盘监听")
            setupEventTap()
        } else if !hasPermission && isMonitoringActive {
            DebugLogger.shared.warning("🔒 权限被撤销，停止键盘监听")
            stopMonitoring()
        } else if hasPermission && isMonitoringActive {
            // 检查事件钩子是否仍然有效
            if let eventTap = eventTap, !CGEvent.tapIsEnabled(tap: eventTap) {
                DebugLogger.shared.warning("🔧 事件钩子失效，重新初始化")
                setupEventTap()
            }
        }
    }
    
    /// 检查辅助功能权限
    func checkAccessibilityPermissions() -> Bool {
        DebugLogger.shared.info("检查辅助功能权限")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let hasPermission = AXIsProcessTrustedWithOptions(options)
        DebugLogger.shared.info("辅助功能权限状态: \(hasPermission ? "已授予" : "未授予")")
        return hasPermission
    }
    
    /// 设置事件钩子
    private func setupEventTap() {
        DebugLogger.shared.info("开始设置事件钩子")
        
        // 先清理现有的事件钩子
        if eventTap != nil {
            DebugLogger.shared.info("清理现有事件钩子")
            stopMonitoring()
        }
        
        guard AXIsProcessTrusted() else {
            DebugLogger.shared.error("缺少辅助功能权限，无法设置事件钩子")
            isMonitoringActive = false
            return
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        DebugLogger.shared.debug("事件掩码: \(eventMask)")
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
                return monitor.handleKeyboardEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            DebugLogger.shared.error("创建事件钩子失败")
            isMonitoringActive = false
            return
        }
        
        DebugLogger.shared.success("事件钩子创建成功")
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoringActive = true
        DebugLogger.shared.success("键盘监听已启动")
    }
    
    
    /// 处理键盘事件
    private func handleKeyboardEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        eventCount += 1
        
        // 只在调试模式下记录键盘事件
        #if DEBUG
        if keyCode == 56 || keyCode == 60 || keyCode == 57 {
            DebugLogger.shared.debug("事件 #\(eventCount): 类型=\(type.rawValue), 键码=\(keyCode)")
        }
        #endif
        
        switch type {
        case .keyDown:
            return handleKeyDown(event: event, keyCode: keyCode)
        case .keyUp:
            return handleKeyUp(event: event, keyCode: keyCode)
        case .flagsChanged:
            return handleFlagsChanged(event: event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }
    
    /// 处理按键按下事件
    private func handleKeyDown(event: CGEvent, keyCode: Int64) -> Unmanaged<CGEvent>? {
        // 如果在Shift按下期间按下了其他键，标记为组合键
        if leftShiftPressed || rightShiftPressed {
            if keyCode != 56 && keyCode != 60 { // 不是左右Shift键
                otherKeyPressed = true
                DebugLogger.shared.debug("⌨️ Shift组合键检测: 在Shift按下期间按下了键码 \(keyCode)")
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    /// 处理按键释放事件
    private func handleKeyUp(event: CGEvent, keyCode: Int64) -> Unmanaged<CGEvent>? {
        return Unmanaged.passUnretained(event)
    }
    
    /// 处理修饰键状态变化
    private func handleFlagsChanged(event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let currentTime = CFAbsoluteTimeGetCurrent()
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        #if DEBUG
        DebugLogger.shared.debug("🔄 flagsChanged: 键码=\(keyCode), flags=\(flags.rawValue)")
        #endif
        
        // 处理Caps Lock键 (keyCode 57)
        if keyCode == 57 {
            capsLockEventCount += 1
            DebugLogger.shared.info("🔒 Caps Lock \(flags.contains(.maskAlphaShift) ? "启用" : "禁用")大小写锁定")
            
            // 修改原始事件的flags，只保留大小写切换功能，移除输入法切换标志
            if flags.contains(.maskAlphaShift) {
                event.flags = .maskAlphaShift
            } else {
                event.flags = []
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 检查左Shift键 (keyCode 56)
        let leftShiftDown = flags.contains(.maskShift) && keyCode == 56
        
        // 检查右Shift键 (keyCode 60)  
        let rightShiftDown = flags.contains(.maskShift) && keyCode == 60
        
        // 左Shift键状态变化
        if !leftShiftPressed && leftShiftDown {
            // 左Shift按下
            leftShiftPressed = true
            shiftPressTime = currentTime
            otherKeyPressed = false
            shiftEventCount += 1
            DebugLogger.shared.info("⬅️ 左Shift按下")
        } else if leftShiftPressed && !leftShiftDown {
            // 左Shift释放
            leftShiftPressed = false
            let duration = currentTime - shiftPressTime
            
            if !otherKeyPressed && duration > 0.05 && duration < 0.5 {
                DebugLogger.shared.success("⬅️ 左Shift切换输入法")
                // 单独按下的Shift键，切换输入法
                DispatchQueue.main.async {
                    _ = InputSourceManager.shared.toggleInputSource()
                }
            }
        }
        
        // 右Shift键状态变化
        if !rightShiftPressed && rightShiftDown {
            // 右Shift按下
            rightShiftPressed = true
            shiftPressTime = currentTime
            otherKeyPressed = false
            shiftEventCount += 1
            DebugLogger.shared.info("➡️ 右Shift按下")
        } else if rightShiftPressed && !rightShiftDown {
            // 右Shift释放
            rightShiftPressed = false
            let duration = currentTime - shiftPressTime
            
            if !otherKeyPressed && duration > 0.05 && duration < 0.5 {
                DebugLogger.shared.success("➡️ 右Shift切换输入法")
                // 单独按下的Shift键，切换输入法
                DispatchQueue.main.async {
                    _ = InputSourceManager.shared.toggleInputSource()
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    /// 停止监听
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        isMonitoringActive = false
        DebugLogger.shared.info("⏹️ 键盘监听已停止")
    }
    
    /// 手动重新初始化监听（用于调试）
    func reinitializeMonitoring() {
        DebugLogger.shared.info("🔄 手动重新初始化键盘监听")
        stopMonitoring()
        setupEventTap()
    }
}

// MARK: - 应用代理类
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var keyboardMonitor: KeyboardMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLogger.shared.success("🚀 ShiftSwitch 应用启动完成")
        setupStatusBar()
        setupKeyboardMonitoring()
        
        // 隐藏应用图标
        NSApp.setActivationPolicy(.accessory)
        DebugLogger.shared.info("🔍 应用设置为后台模式(.accessory)")
        
        // 显示启动信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            DebugLogger.shared.success("ShiftSwitch 已启动，Shift切换输入法，Caps Lock控制大小写")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor?.stopMonitoring()
    }
    
    /// 设置状态栏
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.title = "⌨️"
            statusButton.toolTip = "ShiftSwitch - 键盘输入法切换工具"
        }
        
        let menu = NSMenu()
        
        // 状态菜单项
        let statusMenuItem = NSMenuItem(title: "ShiftSwitch 正在运行", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 权限检查菜单项
        let permissionMenuItem = NSMenuItem(title: "检查权限", action: #selector(checkPermissions), keyEquivalent: "")
        permissionMenuItem.target = self
        menu.addItem(permissionMenuItem)
        
        // 重新初始化菜单项
        let reinitMenuItem = NSMenuItem(title: "重新初始化监听", action: #selector(reinitializeMonitoring), keyEquivalent: "")
        reinitMenuItem.target = self
        menu.addItem(reinitMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出菜单项
        let quitMenuItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        statusItem?.menu = menu
    }
    
    /// 设置键盘监听
    private func setupKeyboardMonitoring() {
        DebugLogger.shared.info("⌨️ 开始设置键盘监听")
        keyboardMonitor = KeyboardMonitor()
        DebugLogger.shared.success("⌨️ 键盘监听设置完成")
    }
    
    /// 检查权限
    @objc private func checkPermissions() {
        let hasPermission = keyboardMonitor?.checkAccessibilityPermissions() ?? false
        
        let alert = NSAlert()
        alert.messageText = "权限状态"
        alert.informativeText = hasPermission ? "✅ 辅助功能权限已授予" : "❌ 需要授予辅助功能权限"
        alert.alertStyle = hasPermission ? .informational : .warning
        
        if !hasPermission {
            alert.addButton(withTitle: "打开系统偏好设置")
            alert.addButton(withTitle: "稍后处理")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        } else {
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    /// 重新初始化监听
    @objc private func reinitializeMonitoring() {
        DebugLogger.shared.info("📱 用户请求重新初始化监听")
        keyboardMonitor?.reinitializeMonitoring()
    }
    
    /// 退出应用
    @objc private func quitApp() {
        keyboardMonitor?.stopMonitoring()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - 主应用结构
@main
struct ShiftSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
