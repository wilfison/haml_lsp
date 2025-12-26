# HAML LSP

A Ruby implementation of the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) for HAML templates. This language server provides intelligent code assistance for HAML files in editors that support LSP.

> [!WARNING]
> This project is currently in early development. Features may be incomplete or unstable. Contributions and feedback are welcome!

## Features

- 🎯 **Syntax Validation**: Real-time diagnostics for HAML syntax errors
- 🔍 **Code Completion**: Intelligent autocomplete for HAML tags and attributes
- � **Rails Routes Completion**: Autocomplete for Rails route helpers when working in a Rails project
- �📝 **Hover Information**: Documentation on hover for HAML elements
- 🔗 **Go to Definition**: Navigate to definitions in your HAML templates
- 🎨 **Formatting**: Code formatting support for HAML files

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'haml_lsp'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install haml_lsp
```

## Usage

### With Visual Studio Code

Install a LSP client extension for VS Code and configure it to use `haml_lsp`.

### With Neovim

Configure your LSP client to use the HAML LSP server:

```lua
require'lspconfig'.haml_lsp.setup{}
```

### Manual Usage

You can start the language server manually:

```bash
haml_lsp --stdio
```

### HAML Autocomplete

HAML LSP provides intelligent autocomplete for HAML syntax as you type:

**HTML Tags**: Autocomplete for all common HTML elements including:

- Structural tags: `div`, `span`, `section`, `article`, `header`, `footer`, `nav`, `main`
- Text elements: `p`, `h1`-`h6`, `strong`, `em`, `code`, `pre`
- Forms: `form`, `input`, `button`, `select`, `textarea`, `label`
- Media: `img`, `video`, `audio`, `iframe`
- Tables: `table`, `thead`, `tbody`, `tr`, `th`, `td`
- And many more...

**HAML Tags**: Autocomplete for HAML-specific syntax with the `%` prefix:

- `%div`, `%span`, `%p`, `%a`, etc.
- Common patterns like `%ul`, `%li`, `%table`, `%tr`, `%td`

**HTML Attributes**: Intelligent attribute suggestions including:

- Global attributes: `id`, `class`, `style`, `title`, `data-*`, `aria-*`
- Tag-specific attributes (e.g., `href` and `target` for `<a>` tags, `src` and `alt` for `<img>` tags)
- Form attributes: `type`, `name`, `value`, `placeholder`, `required`, etc.

**HAML Attribute Syntax**: Shortcuts for HAML-specific attribute notations:

- `.` - Class shortcut (e.g., `%div.container`)
- `#` - ID shortcut (e.g., `%div#main`)
- `{` - Ruby hash attributes (e.g., `%div{class: "container"}`)
- `(` - HTML-style attributes (e.g., `%div(class="container")`)

### Rails Integration

When working in a Rails project, HAML LSP automatically detects your project and provides intelligent autocomplete for Rails route helpers.

**Automatic Detection**: The LSP server automatically detects Rails projects by checking for:

- `config/application.rb`
- `Gemfile`
- `config/routes.rb`

**Route Completion**: When detected as a Rails project, you'll get autocomplete suggestions for all available route helpers (e.g., `users_path`, `new_user_path`, etc.) as you type. The completions include:

- Route helper names
- HTTP methods (GET, POST, PUT, DELETE, etc.)
- URL patterns
- Full route information

The route helpers are extracted by running `rake routes` (or `bundle exec rake routes` if using bundler) when the LSP server initializes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilfison/haml_lsp.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- Built with [language_server-protocol](https://github.com/mtsmfm/language_server-protocol-ruby)
- Powered by [HAML](https://haml.info/)
