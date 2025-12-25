# HAML LSP

A Ruby implementation of the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) for HAML templates. This language server provides intelligent code assistance for HAML files in editors that support LSP.

## Features

- 🎯 **Syntax Validation**: Real-time diagnostics for HAML syntax errors
- 🔍 **Code Completion**: Intelligent autocomplete for HAML tags and attributes
- 📝 **Hover Information**: Documentation on hover for HAML elements
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
