# @subflag/api-types

TypeScript type definitions for the Subflag SDK.

## Installation

```bash
npm install @subflag/api-types
```

## Usage

```typescript
import type { EvaluationContext, EvaluationResult } from '@subflag/api-types';

// Evaluation context for targeting
const context: EvaluationContext = {
  targetingKey: 'user-123',
  kind: 'user',
  attributes: {
    email: 'user@example.com',
    plan: 'premium'
  }
};

// Evaluation result
const result: EvaluationResult = {
  flagKey: 'my-flag',
  value: true,
  variant: 'enabled',
  reason: 'SEGMENT_MATCH'
};
```

## Exported Types

### `EvaluationContext`

Context information sent with flag evaluation requests:
- `targetingKey?: string | null` - Unique identifier (e.g., user ID, session ID)
- `kind: string | null` - Type of context (e.g., "user", "organization", "device")
- `attributes?: Record<string, unknown> | null` - Custom attributes for targeting

### `EvaluationResult`

Result returned from flag evaluations:
- `flagKey: string` - The flag key that was evaluated
- `value: unknown` - Flag value (boolean, string, number, or object)
- `variant: string` - Selected variant name
- `reason: EvaluationReason` - Why this result was returned

### `EvaluationReason`

Possible reasons for evaluation results:
- `'DEFAULT'` - No targeting rules matched, using default variant
- `'OVERRIDE'` - Context-specific override applied
- `'SEGMENT_MATCH'` - Matched a segment targeting rule
- `'PERCENTAGE_ROLLOUT'` - Matched a percentage rollout rule
- `'TARGETING_MATCH'` - Matched a targeting rule (generic)
- `'ERROR'` - Evaluation error occurred

## Bundle Size

**0 bytes runtime** - This package only exports TypeScript types, which are stripped during compilation.

## Used By

- `@subflag/openfeature-web-provider` - Web browser SDK
- `@subflag/openfeature-node-provider` - Node.js server SDK

## License

MIT
