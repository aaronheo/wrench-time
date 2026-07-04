import Foundation
import Supabase

/// Shared Supabase client. Used for authentication only — all data access goes
/// through the backend API (WrenchAPIClient), which is the source of truth.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: Constants.Supabase.url)!,
        supabaseKey: Constants.Supabase.anonKey
    )
}
