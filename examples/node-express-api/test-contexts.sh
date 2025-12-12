#!/bin/bash

# Test script to generate various contexts for the Subflag Contexts UI
# This script makes API calls to the node-express-api to create different context types

API_URL="http://localhost:3001"

echo "🧪 Testing Subflag Contexts UI"
echo "================================"
echo ""

# Test 1: Session contexts (GET /api/products)
echo "📋 Test 1: Creating session contexts..."
echo "  Making requests with different session IDs and user types"
echo ""

for i in {1..3}; do
  SESSION_ID="session-test-$i"
  USER_TYPE=$([ $((i % 2)) -eq 0 ] && echo "premium=true" || echo "premium=false")

  echo "  → Session $i ($USER_TYPE)"
  curl -s -X GET "$API_URL/api/products?user=tester$i@example.com&$USER_TYPE" \
    -H "X-Session-ID: $SESSION_ID" \
    -H "X-Country: US" \
    | jq -r '.message' 2>/dev/null || echo "  Request completed"

  sleep 0.5
done

echo ""
echo "✅ Session contexts created"
echo ""

# Test 2: User contexts (GET /api/products/:id)
echo "📋 Test 2: Creating user contexts..."
echo "  Making requests for specific products with different users"
echo ""

for i in {1..3}; do
  USER_ID="user-$((100 + i))"
  PRODUCT_ID=$i
  PREMIUM=$([ $((i % 2)) -eq 0 ] && echo "premium=true" || echo "premium=false")

  echo "  → User $USER_ID viewing product $PRODUCT_ID ($PREMIUM)"
  curl -s -X GET "$API_URL/api/products/$PRODUCT_ID?userId=$USER_ID&email=$USER_ID@example.com&$PREMIUM" \
    -H "X-Country: $([ $((i % 2)) -eq 0 ] && echo 'CA' || echo 'US')" \
    | jq -r '.success' 2>/dev/null || echo "  Request completed"

  sleep 0.5
done

echo ""
echo "✅ User contexts created"
echo ""

# Test 3: Device contexts (GET /api/health)
echo "📋 Test 3: Creating device contexts..."
echo "  Making health check requests from different devices"
echo ""

# Desktop Chrome
echo "  → Desktop Chrome device"
curl -s -X GET "$API_URL/api/health" \
  -H "X-Device-ID: device-chrome-desktop" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0" \
  -H "X-Screen-Resolution: 1920x1080" \
  -H "Accept-Language: en-US,en;q=0.9" \
  | jq -r '.status' 2>/dev/null || echo "  Request completed"

sleep 0.5

# Mobile Safari
echo "  → Mobile Safari device"
curl -s -X GET "$API_URL/api/health" \
  -H "X-Device-ID: device-safari-mobile" \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1" \
  -H "X-Screen-Resolution: 390x844" \
  -H "Accept-Language: en-US,en;q=0.9" \
  | jq -r '.status' 2>/dev/null || echo "  Request completed"

sleep 0.5

# Desktop Firefox
echo "  → Desktop Firefox device"
curl -s -X GET "$API_URL/api/health" \
  -H "X-Device-ID: device-firefox-desktop" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
  -H "X-Screen-Resolution: 2560x1440" \
  -H "Accept-Language: en-GB,en;q=0.9" \
  | jq -r '.status' 2>/dev/null || echo "  Request completed"

echo ""
echo "✅ Device contexts created"
echo ""

# Test 4: Generate evaluation history
echo "📋 Test 4: Generating evaluation history..."
echo "  Making repeated flag evaluations to populate debug logs"
echo ""

# Generate history for a specific device context
echo "  → Creating evaluation history for device-firefox-desktop"
for i in {1..5}; do
  echo "    Evaluation $i/5"
  curl -s -X GET "$API_URL/api/health" \
    -H "X-Device-ID: device-firefox-desktop" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
    -H "X-Screen-Resolution: 2560x1440" \
    -H "Accept-Language: en-GB,en;q=0.9" \
    > /dev/null 2>&1

  sleep 0.3
done

# Generate history for a specific user context
echo "  → Creating evaluation history for user-101"
for i in {1..5}; do
  echo "    Evaluation $i/5"
  curl -s -X GET "$API_URL/api/products/1?userId=user-101&email=user-101@example.com&premium=true" \
    -H "X-Country: CA" \
    > /dev/null 2>&1

  sleep 0.3
done

# Generate history for a specific session context
echo "  → Creating evaluation history for session-test-1"
for i in {1..5}; do
  echo "    Evaluation $i/5"
  curl -s -X GET "$API_URL/api/products?user=tester1@example.com&premium=false" \
    -H "X-Session-ID: session-test-1" \
    -H "X-Country: US" \
    > /dev/null 2>&1

  sleep 0.3
done

echo ""
echo "✅ Evaluation history generated"
echo ""

# Summary
echo "================================"
echo "✨ Context generation complete!"
echo ""
echo "You should now see the following in the Contexts UI:"
echo "  • 3 session contexts (session-test-1, 2, 3)"
echo "  • 3 user contexts (user-101, 102, 103)"
echo "  • 3 device contexts (chrome-desktop, safari-mobile, firefox-desktop)"
echo ""
echo "📊 Evaluation History:"
echo "  • device-firefox-desktop: ~20 evaluations (4 flags × 5 calls)"
echo "  • user-101: ~15 evaluations (3 flags × 5 calls)"
echo "  • session-test-1: ~25 evaluations (5 flags × 5 calls)"
echo ""
echo "🌐 Open the Subflag UI and navigate to:"
echo "   Projects → [Your Project] → Contexts"
echo ""
echo "Try filtering by kind: user, session, or device"
echo "Click 'View' on any context to see its attributes"
echo "Click 'View History' to see the evaluation debug logs!"
echo ""
