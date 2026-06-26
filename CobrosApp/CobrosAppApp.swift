//
//  CobrosAppApp.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import SwiftUI

@main
struct CobrosAppApp: App {
    @State private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
        }
    }
}
