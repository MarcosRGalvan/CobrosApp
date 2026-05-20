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
    
    let client: SupabaseClient
    
    private init() {
        let url = URL(string: "https://yzjxmtemhlliyrisxgce.supabase.co")!
        let anonKey = "sb_publishable_gIVRzGOyzFQ9cv1iaYKhtg_XMPF9ZOr"
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
