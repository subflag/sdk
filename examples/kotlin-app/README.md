# Kotlin Example App

A simple Kotlin application demonstrating the Subflag OpenFeature provider.

## Prerequisites

- JDK 17+
- A running Subflag server (local or production)
- An SDK API key

## Setup

1. **Copy the environment file:**

   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your API key:**

   ```bash
   SUBFLAG_API_URL=http://localhost:8080
   SUBFLAG_API_KEY=sdk-development-my-app-xxxxx
   ```

   Get an API key from the Subflag dashboard: Settings → Applications → Create Application

3. **Create some flags in Subflag:**

   - `new-feature` (boolean)
   - `button-color` (string)
   - `max-items` (integer)
   - `premium-feature` (boolean)

## Running

```bash
# Load environment variables and run
export $(cat .env | xargs) && ./gradlew run
```

Or on Windows:

```powershell
# Set environment variables manually, then:
.\gradlew.bat run
```

## Expected Output

```
🚀 Subflag Kotlin SDK Example
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
API URL: http://localhost:8080

📋 Evaluating flags...

  new-feature (boolean): true
  button-color (string): green
  max-items (integer): 25

👤 Evaluating with user context...

  premium-feature for enterprise user: true

🔍 Getting evaluation details...

  Flag: new-feature
  Value: true
  Variant: enabled
  Reason: TARGETING_MATCH

✅ Done!
```

## How It Works

This example demonstrates:

1. **Provider initialization** - Creating a `SubflagProvider` with API URL and key
2. **Simple flag evaluation** - Getting boolean, string, and integer values
3. **Contextual evaluation** - Passing user attributes for targeting rules
4. **Evaluation details** - Getting variant names and evaluation reasons

Each flag evaluation makes an API call to the Subflag server, ensuring you always get the latest value.
