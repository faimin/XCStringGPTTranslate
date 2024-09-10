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
        }

        Settings {
            SettingView()
        }
    }
}
