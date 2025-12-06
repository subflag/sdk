# Subflag SDKs

[![npm @subflag/openfeature-web-provider](https://img.shields.io/npm/v/@subflag/openfeature-web-provider?label=web-provider)](https://www.npmjs.com/package/@subflag/openfeature-web-provider)
[![npm @subflag/openfeature-node-provider](https://img.shields.io/npm/v/@subflag/openfeature-node-provider?label=node-provider)](https://www.npmjs.com/package/@subflag/openfeature-node-provider)
[![gem subflag-openfeature-provider](https://img.shields.io/gem/v/subflag-openfeature-provider?label=ruby-provider)](https://rubygems.org/gems/subflag-openfeature-provider)

Official SDKs for [Subflag](https://subflag.com) feature flag management.

## SDKs

| SDK | Language | Framework | Install |
|-----|----------|-----------|---------|
| [Web Provider](./packages/openfeature-web-provider) | TypeScript | React, Vue, etc. | `npm install @subflag/openfeature-web-provider` |
| [Node Provider](./packages/openfeature-node-provider) | TypeScript | Express, Fastify, etc. | `npm install @subflag/openfeature-node-provider` |
| [Ruby Provider](./packages/openfeature-ruby-provider) | Ruby | OpenFeature SDK | `gem install subflag-openfeature-provider` |
| [Kotlin Provider](./packages/openfeature-kotlin-provider) | Kotlin/Java | Android, Spring, Ktor | [JitPack](./packages/openfeature-kotlin-provider) |
| [Rails](./packages/subflag-rails) | Ruby | Rails | `gem install subflag-rails` |

## OpenFeature

The Web, Node, Ruby, and Kotlin providers are [OpenFeature](https://openfeature.dev)-compliant, providing a vendor-neutral API for feature flags. The Rails SDK offers a more idiomatic Rails experience with helpers and view integration.

## Getting Started

1. **Sign up** at [subflag.com](https://subflag.com)
2. **Create a project** with environments (dev, staging, production)
3. **Create feature flags** and configure variants
4. **Generate an API key** for your environment
5. **Install an SDK** and start evaluating flags

## License

MIT
