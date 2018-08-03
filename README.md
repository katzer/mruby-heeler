# The [Shelf][shelf] middleware that enables compression <br> [![Build Status](https://travis-ci.org/katzer/mruby-shelf-deflater.svg?branch=master)](https://travis-ci.org/katzer/mruby-shelf-deflater) [![Build status](https://ci.appveyor.com/api/projects/status/t5r91stl062nl7ya/branch/master?svg=true)](https://ci.appveyor.com/project/katzer/mruby-shelf-deflater/branch/master) [![Maintainability](https://api.codeclimate.com/v1/badges/99432e2a785e24eea5d2/maintainability)](https://codeclimate.com/github/katzer/mruby-shelf-deflater/maintainability)

Code based on [Rack::Deflator][rack]. Currently supported compression algorithms:

* gzip
* deflate
* identity (no transformation)

## Usage

```ruby
Shelf::Builder.app do
  use Deflator, include: 'text/html', if: ->(req, status, headers, body) { headers['Content-Length'] > 512 }
end
```

## Installation

Add the line below to your `build_config.rb`:

```ruby
MRuby::Build.new do |conf|
  # ... (snip) ...
  conf.gem 'mruby-shelf-deflator'
end
```

Or add this line to your aplication's `mrbgem.rake`:

```ruby
MRuby::Gem::Specification.new('your-mrbgem') do |spec|
  # ... (snip) ...
  spec.add_dependency 'mruby-shelf-deflator'
end
```

__Note:__ Compile file `ZLIB_STATIC` flag if you want to static link with zlib. See the [build_config.rb][build_config] as an example.

## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-shelf-deflator.git && cd mruby-shelf-deflator/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katzer/mruby-shelf-deflator.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

- Sebastián Katzer, Fa. appPlant GmbH

## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: from Leipzig

© 2018 [appPlant GmbH][appplant]

[shelf]: https://github.com/katzer/mruby-shelf
[rack]: https://github.com/rack/rack/blob/master/lib/rack/deflater.rb
[build_config]: https://github.com/katzer/mruby-shelf-deflater/blob/master/build_config.rb
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de
