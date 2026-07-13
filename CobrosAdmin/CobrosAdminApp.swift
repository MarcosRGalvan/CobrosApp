//
//  CobrosAdminApp.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

@main
struct CobrosAdminApp: App {
    @State private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootAdminView()
                .environment(authViewModel)
        }
        .defaultSize(width: 1200, height: 800)
    }
}
