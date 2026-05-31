//
//  SupabaseManager.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://yzjxmtemhlliyrisxgce.supabase.co")!,
        supabaseKey: "sb_publishable_gIVRzGOyzFQ9cv1iaYKhtg_XMPF9ZOr",
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}
