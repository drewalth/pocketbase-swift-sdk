import Testing
@testable import PocketBase

@Test("Setup: Clear all storage before tests")
func setup_clear_storage() async throws {
  let secureStorage = SecureStorage()
  secureStorage.clearAllTokens()
  secureStorage.clearFallbackStorage()
  print("✅ Storage cleared before tests")
}

@Test("Teardown: Clear all storage after tests")
func teardown_clear_storage() async throws {
  let secureStorage = SecureStorage()
  secureStorage.clearAllTokens()
  secureStorage.clearFallbackStorage()
  print("✅ Storage cleared after tests")
}
