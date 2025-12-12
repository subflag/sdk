package com.example

import com.subflag.openfeature.SubflagProvider
import dev.openfeature.sdk.ImmutableContext
import dev.openfeature.sdk.OpenFeatureAPI
import dev.openfeature.sdk.Value

/**
 * Example Kotlin application demonstrating the Subflag OpenFeature provider.
 *
 * Before running:
 * 1. Start the Subflag server or use https://api.subflag.com
 * 2. Create a project with some flags
 * 3. Generate an SDK API key and set SUBFLAG_API_KEY environment variable
 */
fun main() {
    val apiUrl = System.getenv("SUBFLAG_API_URL") ?: "http://localhost:8080"
    val apiKey = System.getenv("SUBFLAG_API_KEY")
        ?: error("SUBFLAG_API_KEY environment variable is required")

    println("🚀 Subflag Kotlin SDK Example")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("API URL: $apiUrl")
    println()

    // Initialize the Subflag provider
    val provider = SubflagProvider(
        apiUrl = apiUrl,
        apiKey = apiKey
    )

    // Set it as the OpenFeature provider
    OpenFeatureAPI.getInstance().setProvider(provider)

    // Get a client
    val client = OpenFeatureAPI.getInstance().client

    // Example 1: Simple flag evaluations
    println("📋 Evaluating flags...")
    println()

    val showNewFeature = client.getBooleanValue("new-feature", false)
    println("  new-feature (boolean): $showNewFeature")

    val buttonColor = client.getStringValue("button-color", "blue")
    println("  button-color (string): $buttonColor")

    val maxItems = client.getIntegerValue("max-items", 10)
    println("  max-items (integer): $maxItems")

    println()

    // Example 2: Evaluation with user context for targeting
    println("👤 Evaluating with user context...")
    println()

    val userContext = ImmutableContext(
        "user-123",
        mapOf(
            "email" to Value("premium@example.com"),
            "plan" to Value("enterprise"),
            "country" to Value("US")
        )
    )

    val premiumFeature = client.getBooleanValue("premium-feature", false, userContext)
    println("  premium-feature for enterprise user: $premiumFeature")

    println()

    // Example 3: Getting detailed evaluation info
    println("🔍 Getting evaluation details...")
    println()

    val details = client.getBooleanDetails("new-feature", false)
    println("  Flag: new-feature")
    println("  Value: ${details.value}")
    println("  Variant: ${details.variant ?: "N/A"}")
    println("  Reason: ${details.reason}")
    if (details.errorCode != null) {
        println("  Error: ${details.errorCode} - ${details.errorMessage}")
    }

    println()
    println("✅ Done!")
}
