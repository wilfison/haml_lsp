# Project Overview

HAML LSP is a Ruby implementation of the Language Server Protocol for HAML templates, providing
intelligent code assistance including syntax validation, autocomplete for tags/attributes, Rails
route helpers, hover documentation, formatting, and code actions. This early-stage gem integrates
with LSP-compatible editors to enhance HAML development workflows.

## Repository Structure

- **bin/** – Development utilities (`console`, `setup`)
- **exe/** – Executable entry point (`haml_lsp` binary that starts the LSP server)
- **lib/** – Core library code: server, linter, autocomplete providers, message protocol handlers
- **lib/haml_lsp/** – Main modules: `Server`, `Linter`, `Store`, `Document`, autocorrector, utils
- **lib/haml_lsp/haml/** – HAML-specific providers (tags, attributes)
- **lib/haml_lsp/lint/** – Linting engine integration with `haml_lint`
- **lib/haml_lsp/message/** – LSP message reader/writer/notification/request/result handlers
- **lib/haml_lsp/rails/** – Rails project detection and routes extraction for autocomplete
- **pkg/** – Built gem artifacts
- **sig/** – RBS type signatures for type-checking
- **test/** – Minitest suite covering all components

## Build & Development Commands

**Install dependencies:**

```bash
bundle install
```

**Run tests:**

```bash
bundle exec rake test
```

**Run linter (RuboCop):**

```bash
bundle exec rake rubocop
```

**Run default task (test + rubocop):**

```bash
bundle exec rake
```

**Build the gem:**

```bash
bundle exec rake build
```

**Install gem locally:**

```bash
bundle exec rake install
```

**Start the LSP server manually:**

```bash
bundle exec haml_lsp --stdio
# Optional flags:
# --use-bundle     Use bundler context
# --enable-lint    Enable linting diagnostics
# --root-uri=...   Set workspace root
```

**Interactive console:**

```bash
bin/console
```

## Code Style & Conventions

**Formatting:**

- Ruby 3.2+ required
- Double quotes for strings (`"example"`)
- Frozen string literal pragma on all files (`# frozen_string_literal: true`)
- Nested class/module style enforced (`class Outer; class Inner; end; end`)
- Max method length: 20 lines (configurable exceptions for complex handlers)

**Naming:**

- Snake_case for files, methods, variables
- PascalCase for classes and modules
- Private methods at the bottom of classes

**Lint config:**

- `.rubocop.yml` with RuboCop, rubocop-minitest, rubocop-rake
- Target Ruby 3.2+
- NewCops enabled automatically
- Minitest multiple-assertion rule disabled for tests

**Commit messages:**

> TODO: Document commit message conventions if applicable

## Architecture Notes

```
┌─────────────────────────────────────────────────────────────────┐
│                        LSP Client (Editor)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ JSON-RPC over stdio
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      HamlLsp::Server                             │
│  - handles LSP lifecycle (initialize, shutdown)                  │
│  - routes requests to responders                                 │
│  - manages document store                                        │
└─┬──────────┬──────────┬──────────┬──────────┬────────────────────┘
  │          │          │          │          │
  │          │          │          │          │
┌─▼────┐  ┌─▼────┐  ┌──▼──────┐ ┌─▼────┐  ┌─▼──────────────────┐
│Store │  │Linter│  │Document │ │Auto  │  │ServerResponder     │
│      │  │      │  │         │ │corr. │  │- LSP response fmt  │
└──────┘  └──┬───┘  └─────────┘ └──────┘  └────────────────────┘
             │
       ┌─────▼────────┐
       │ Lint::Runner │──> haml_lint integration
       └──────────────┘

┌────────────────────────────────────────────────────────────────┐
│  Completion Providers                                           │
│  - Haml::TagsProvider     (HTML/HAML tags)                      │
│  - Haml::AttributesProvider (attrs, shortcuts)                  │
│  - Rails::RoutesExtractor (route helpers if Rails detected)     │
└────────────────────────────────────────────────────────────────┘
```

**Data flow:**

1. Editor sends JSON-RPC request via stdio to `HamlLsp::Server`
2. `Message::Reader` parses incoming messages; `Message::Writer` formats outbound
3. Server dispatches to handlers (`handle_initialize`, `handle_completion`, etc.)
4. `Store` maintains in-memory document cache keyed by URI
5. `Linter` delegates to `Lint::Runner` (wraps `haml_lint`), returns LSP `Diagnostic` structs
6. `Autocorrector` formats HAML using `haml_lint` auto-fix
7. Completion: if Rails detected (`Rails::Detector`), merge route helpers with tag/attribute
   providers
8. `ServerResponder` marshals results into LSP protocol objects (via `language_server-protocol`)

## Testing Strategy

**Framework:** Minitest (autorun)

**Coverage:**

- **Unit tests** for each major component (`*_test.rb` files in `test/`)
- `test/haml_lsp_test.rb` – main module sanity
- `test/server_test.rb`, `server_responder_test.rb` – LSP lifecycle and message handling
- `test/linter_test.rb`, `lint_runner_test.rb` – diagnostics generation
- `test/autocorrector_test.rb` – formatting
- `test/haml_*_provider_test.rb` – completion sources
- `test/rails_*.rb` – Rails detection and route extraction
- `test/message_classes_test.rb` – protocol message serialization
- `test/document_test.rb`, `store_test.rb` – document state management

**Running locally:**

```bash
bundle exec rake test
```

**CI:**

> TODO: Document CI configuration (GitHub Actions, etc.) if present

**Test helpers:**

- `test/test_helper.rb` sets log level to `fatal` to suppress noise
- IRB loaded for debugging sessions

## Security & Compliance

**Secrets handling:**

> TODO: Document any secrets management if LSP needs credentials

**Dependency scanning:**

- RuboCop runs on every commit to catch style/security issues
- `rubygems_mfa_required: true` in gemspec for publish security

**License:**

- MIT License (see `LICENSE.txt`)

**Guardrails:**

- Required Ruby ≥ 3.2.0
- Dependencies: `haml_lint ~> 0.67`, `language_server-protocol ~> 3.17.0`
- No known CVEs at time of writing; monitor `bundle audit` periodically

## Agent Guardrails

**Files never touched by automated agents:**

- `pkg/` – Generated gem artifacts
- `sig/` – Type signatures (manual curation required)
- `bin/console`, `bin/setup` – Developer scripts
- `.git/`, `.bundle/` – Version control and local bundle state

**Required human reviews:**

- Changes to LSP protocol handling (`lib/haml_lsp/server.rb`, `server_responder.rb`)
- New completion providers or Rails integration logic
- Gemspec version bumps or dependency updates
- Test fixtures that validate LSP message formats

**Rate limits:**

- No external API calls in normal operation; LSP is local-only
- Linting runs synchronously on `didChange`; may block on large files

**Coding boundaries:**

- Do not auto-generate RBS signatures without cross-checking against actual usage
- Preserve frozen string literal comments
- Maintain test coverage for new features

## Extensibility Hooks

**Plugin points:**

> TODO: Document if provider registration becomes pluggable

**Environment variables:**

- `HAML_LSP_LOG_LEVEL` – Controls logging verbosity (set to `fatal` in tests)
- `PWD` – Fallback workspace root if `--root-uri` not provided

**Feature flags:**

- `--use-bundle` – Run under Bundler context (useful in monorepos)
- `--enable-lint` – Enable real-time linting diagnostics (disabled by default)
- `--root-uri=file://...` – Explicit workspace root for Rails detection

**Configuration files:**

- `.haml-lint.yml` or `config/haml-lint.yml` – Linter rules (auto-discovered in workspace)

## Further Reading

- [CHANGELOG.md](CHANGELOG.md) – Release history (currently shows `[UNRELEASED]`)
- [README.md](README.md) – User-facing installation and usage guide
- [Language Server Protocol spec](https://microsoft.github.io/language-server-protocol/)
- [haml_lint documentation](https://github.com/sds/haml-lint)

> TODO: Link to ARCHITECTURE.md or ADRs when available
> TODO: Link to CONTRIBUTING.md for contributor guidelines
