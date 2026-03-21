# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HAML LSP is a Ruby gem implementing the Language Server Protocol for HAML files. It provides autocomplete, go-to-definition, formatting, diagnostics (via haml_lint), code actions, and Rails integration (routes, partials, assets).

## Common Commands

```bash
bundle exec rake test        # Run full test suite
bundle exec rake rubocop     # Run linter
bundle exec rake             # Run both tests and rubocop (default task)
bundle exec ruby -Ilib:test test/path/to/test_file.rb  # Run a single test file
```

The executable is at `exe/haml_lsp` and accepts `--use-bundle`, `--enable-lint`, and `--root-uri=<path>` flags.

## Architecture

The server communicates over stdio using JSON-RPC (LSP protocol). The main data flow is:

```
stdin → Message::Reader → Server::Base → RequestHandler → Provider → Message::Writer → stdout
```

**Key layers:**

- **Server** (`lib/haml_lsp/server/`): `Base` orchestrates the server loop. `RequestHandler` uses a strategy pattern mapping LSP method names to handler methods. `Capabilities` declares supported features. `StateManager` and `CacheManager` manage lifecycle and cached data (e.g., Rails routes).

- **Document Store** (`lib/haml_lsp/store.rb`): In-memory LRU cache of open documents with TTL eviction. Each `Document` wraps content with URI and diagnostics.

- **Providers** (`lib/haml_lsp/completion/`, `definition/`, `action/`): Each feature area has a coordinator `Provider` class that delegates to specialized subproviders (e.g., `Completion::Routes`, `Completion::Partials`, `Definition::Assets`).

- **Autocorrect** (`lib/haml_lsp/autocorrect/`): `Base` coordinates multiple autocorrection modules (trailing whitespace, indentation, rubocop, etc.) used for formatting and code actions.

- **Linting** (`lib/haml_lsp/linter.rb`, `lib/haml_lsp/lint/`): Wraps `haml_lint` to produce LSP diagnostics. Looks for `.haml-lint.yml` or `config/haml-lint.yml`.

- **Rails Integration** (`lib/haml_lsp/rails/`): `Detector` checks for Rails project markers. `RoutesExtractor` parses `rails routes --expanded` output for route completion and go-to-definition.

- **Messages** (`lib/haml_lsp/message/`): Reader/Writer handle Content-Length framed JSON-RPC over stdio. Request, Notification, and Result wrap message types.

## Code Style

- Ruby >= 3.2, frozen string literals enforced
- RuboCop with `rubocop-minitest` and `rubocop-rake` plugins
- Double quotes preferred
- Tests use Minitest with a `MockRequest` helper (see `test/test_helper.rb`)
