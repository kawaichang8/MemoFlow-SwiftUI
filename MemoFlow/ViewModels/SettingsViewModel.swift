//
//  SettingsViewModel.swift
//  MemoFlow
//
//  設定画面のViewModel
//

import Foundation
import SwiftUI

/// 設定ViewModel
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Properties
    private let settings = AppSettings.shared
    
    // MARK: - General Settings
    
    var defaultDestination: Destination {
        get { settings.defaultDestination }
        set { settings.defaultDestination = newValue }
    }
    
    var tagAutoMode: TagAutoMode {
        get { settings.tagAutoMode }
        set { settings.tagAutoMode = newValue }
    }
    
    var hapticEnabled: Bool {
        get { settings.hapticEnabled }
        set { settings.hapticEnabled = newValue }
    }
    
    var soundEnabled: Bool {
        get { settings.soundEnabled }
        set { settings.soundEnabled = newValue }
    }
    
    var appearanceMode: Int {
        get { settings.appearanceMode }
        set { settings.appearanceMode = newValue }
    }
    
    // MARK: - Notion Settings
    
    var notionAPIKey: String {
        get { settings.notionAPIKey }
        set { settings.notionAPIKey = newValue }
    }
    
    var notionDatabaseId: String {
        get { settings.notionDatabaseId }
        set { settings.notionDatabaseId = newValue }
    }
    
    var isNotionConfigured: Bool {
        settings.isNotionConfigured
    }
    
    // MARK: - Todoist Settings
    
    var todoistAPIKey: String {
        get { settings.todoistAPIKey }
        set { settings.todoistAPIKey = newValue }
    }
    
    var todoistProjectId: String {
        get { settings.todoistProjectId }
        set { settings.todoistProjectId = newValue }
    }
    
    var isTodoistConfigured: Bool {
        settings.isTodoistConfigured
    }
    
    // MARK: - Slack Settings
    
    var slackBotToken: String {
        get { settings.slackBotToken }
        set { settings.slackBotToken = newValue }
    }
    
    var slackChannelId: String {
        get { settings.slackChannelId }
        set { settings.slackChannelId = newValue }
    }
    
    var isSlackConfigured: Bool {
        settings.isSlackConfigured
    }
    
    // MARK: - Reflect Settings
    
    var reflectAPIKey: String {
        get { settings.reflectAPIKey }
        set { settings.reflectAPIKey = newValue }
    }
    
    var isReflectConfigured: Bool {
        settings.isReflectConfigured
    }
    
    // MARK: - Connection Test State
    
    var isTestingNotion = false
    var notionTestResult: Bool?
    var notionTestError: String?
    
    var isTestingTodoist = false
    var todoistTestResult: Bool?
    var todoistTestError: String?
    
    var isTestingSlack = false
    var slackTestResult: Bool?
    var slackTestError: String?
    
    // MARK: - Methods
    
    /// Notion接続テスト
    func testNotionConnection() async {
        isTestingNotion = true
        notionTestResult = nil
        notionTestError = nil
        
        do {
            let success = try await NotionService.shared.testConnection()
            notionTestResult = success
        } catch {
            notionTestResult = false
            notionTestError = error.localizedDescription
        }
        
        isTestingNotion = false
    }
    
    /// Todoist接続テスト
    func testTodoistConnection() async {
        isTestingTodoist = true
        todoistTestResult = nil
        todoistTestError = nil
        
        do {
            let success = try await TodoistService.shared.testConnection()
            todoistTestResult = success
        } catch {
            todoistTestResult = false
            todoistTestError = error.localizedDescription
        }
        
        isTestingTodoist = false
    }
    
    /// Slack接続テスト
    func testSlackConnection() async {
        isTestingSlack = true
        slackTestResult = nil
        slackTestError = nil
        
        do {
            let success = try await SlackService.shared.testConnection()
            slackTestResult = success
        } catch {
            slackTestResult = false
            slackTestError = error.localizedDescription
        }
        
        isTestingSlack = false
    }
    
    /// 設定をリセット
    func resetAllSettings() {
        settings.reset()
    }
    
    /// 送信先が設定済みかチェック
    func isDestinationConfigured(_ destination: Destination) -> Bool {
        settings.isDestinationConfigured(destination)
    }
}

