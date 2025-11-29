# Subflag OpenFeature Kotlin Provider

OpenFeature provider for [Subflag](https://subflag.com) feature flags, built for Kotlin and Java applications.

## Installation

### Gradle (Kotlin DSL)

```kotlin
repositories {
    mavenCentral()
}

dependencies {
    implementation("com.subflag:openfeature-kotlin-provider:0.1.0")
}
```

### Gradle (Groovy)

```groovy
repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.subflag:openfeature-kotlin-provider:0.1.0'
}
```

### Maven

```xml
<dependency>
    <groupId>com.subflag</groupId>
    <artifactId>openfeature-kotlin-provider</artifactId>
    <version>0.1.0</version>
</dependency>
```

## Quick Start

### Kotlin

```kotlin
import com.subflag.openfeature.SubflagProvider
import dev.openfeature.sdk.OpenFeatureAPI

fun main() {
    // Initialize the provider
    val provider = SubflagProvider(
        apiUrl = "https://api.subflag.com",
        apiKey = "sdk-prod-myapp-abc123..."
    )

    // Set it as the OpenFeature provider
    OpenFeatureAPI.getInstance().setProvider(provider)

    // Get a client and evaluate flags
    val client = OpenFeatureAPI.getInstance().client

    val showNewFeature = client.getBooleanValue("new-feature", false)
    val buttonColor = client.getStringValue("button-color", "blue")
    val maxItems = client.getIntegerValue("max-items", 10)
}
```

### Java

```java
import com.subflag.openfeature.SubflagProvider;
import dev.openfeature.sdk.OpenFeatureAPI;
import dev.openfeature.sdk.Client;

public class Main {
    public static void main(String[] args) {
        // Initialize the provider
        SubflagProvider provider = new SubflagProvider(
            "https://api.subflag.com",
            "sdk-prod-myapp-abc123..."
        );

        // Set it as the OpenFeature provider
        OpenFeatureAPI.getInstance().setProvider(provider);

        // Get a client and evaluate flags
        Client client = OpenFeatureAPI.getInstance().getClient();

        boolean showNewFeature = client.getBooleanValue("new-feature", false);
        String buttonColor = client.getStringValue("button-color", "blue");
        int maxItems = client.getIntegerValue("max-items", 10);
    }
}
```

## Evaluation Context

Pass user/session information to enable targeting:

### Kotlin

```kotlin
import dev.openfeature.sdk.ImmutableContext
import dev.openfeature.sdk.Value

val context = ImmutableContext(
    targetingKey = "user-123",
    attributes = mapOf(
        "email" to Value("user@example.com"),
        "plan" to Value("premium"),
        "country" to Value("US")
    )
)

val showFeature = client.getBooleanValue("premium-feature", false, context)
```

### Java

```java
import dev.openfeature.sdk.ImmutableContext;
import dev.openfeature.sdk.Value;

ImmutableContext context = new ImmutableContext(
    "user-123",
    Map.of(
        "email", new Value("user@example.com"),
        "plan", new Value("premium"),
        "country", new Value("US")
    )
);

boolean showFeature = client.getBooleanValue("premium-feature", false, context);
```

## Configuration Options

### Custom Timeout

```kotlin
import java.time.Duration

val provider = SubflagProvider(
    apiUrl = "https://api.subflag.com",
    apiKey = "sdk-prod-...",
    timeout = Duration.ofSeconds(10)
)
```

### Custom HTTP Client

For advanced use cases like logging, proxies, or custom SSL:

```kotlin
import io.ktor.client.*
import io.ktor.client.engine.cio.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.serialization.jackson.*

val customHttpClient = HttpClient(CIO) {
    install(ContentNegotiation) { jackson() }
    install(Logging) { level = LogLevel.INFO }
    // Add proxy, SSL, retry logic, etc.
}

val provider = SubflagProvider(
    apiUrl = "https://api.subflag.com",
    apiKey = "sdk-prod-...",
    httpClient = customHttpClient
)
```

## Supported Value Types

| Type | Kotlin Method | Java Method |
|------|---------------|-------------|
| Boolean | `getBooleanValue()` | `getBooleanValue()` |
| String | `getStringValue()` | `getStringValue()` |
| Integer | `getIntegerValue()` | `getIntegerValue()` |
| Double | `getDoubleValue()` | `getDoubleValue()` |
| Object | `getObjectValue()` | `getObjectValue()` |

## Error Handling

The provider follows OpenFeature's error handling conventions. On errors, it returns the default value along with error details:

```kotlin
val details = client.getBooleanDetails("my-flag", false)

if (details.errorCode != null) {
    println("Error: ${details.errorCode} - ${details.errorMessage}")
} else {
    println("Flag value: ${details.value}, reason: ${details.reason}")
}
```

### Error Codes

| Scenario | Error Code |
|----------|------------|
| Invalid/expired API key | `INVALID_CONTEXT` |
| Flag not found | `FLAG_NOT_FOUND` |
| Type mismatch | `TYPE_MISMATCH` |
| Network/timeout errors | `GENERAL` |

## Requirements

- JDK 11+
- Kotlin 1.9+ (for Kotlin projects)

## License

MIT
