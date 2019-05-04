# HamdownCore

Core compiler Hamdown into Haml

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hamdown_core'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hamdown_core

## Usage

```bash
./exe/hamdown_core input.hd
```

## Debuging

parse

```bash
./exe/hamdown_parser input.hd
```

transformer

```bash
./exe/hamdown_transformer input.hd
```

compiler

```bash
./exe/hamdown_compiler input.hd
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kopylovvlad/hamdown_core.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## TODO

- Fix code by Rubocop
- To write tests
- add code markdown block feature
