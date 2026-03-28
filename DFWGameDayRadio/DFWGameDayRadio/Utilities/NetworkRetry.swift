import Foundation

enum NetworkRetry {
    /// Retries an async operation with exponential backoff.
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default 3).
    ///   - baseDelay: Initial delay in seconds before first retry (default 2.0).
    ///   - operation: The async throwing operation to retry.
    /// - Returns: The result of the operation on success.
    static func withBackoff<T>(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 2.0,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
        throw lastError!
    }
}
