//
//  GPTxcstringTranslateApp.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

@main
struct GPTxcstringTranslateApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .openSettingsAccess()
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        await StoreService.shared.fetchActiveTransactions()
                    }
                }
        }

        Settings {
            SettingView()
        }
    }
}
