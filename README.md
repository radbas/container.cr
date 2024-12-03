# Container.cr

Simple and small DI Container.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     radbas-container:
       github: radbas/container.cr
   ```

2. Run `shards install`

## Usage

Extend the abstract `Radbas::Container` class and register/autowire your services:

```crystal
require "radbas-container"

class MyService
  def initialize(
    @dep: DependencyService
  ); end
end

class MyContainer < Radbas::Container

  # autowire does let you register namespaces
  # from which classes get resolved automatically
  autowire(MyApp, CustomNamespace)

  # softmap registers all subclasses of a given abstract class
  softmap(MyAbstractClass, params: {}, public: false)

  # register a single service
  register(DependencyService)

  # a factory can be used for setup
  register(MyService, factory: ->{

    # you can call get inside a factory to resolve dependencies
    MyService.new(get(DependencyService))
  }, public: true)

   # params can be used to configure constructor params
  register(MyService, params: { dep: get(DependencyService) })
end
```

By default, all registered services are `private`. Normally you would register a single class as a `public` entrypoint and call `get` on the container:

```crystal
class MyContainer < Radbas::Container
  register(MyApplication, public: true)
end

container = MyContainer.new
app = container.get(MyApplication)
app.run
# ...
```

## Contributing

1. Fork it (<https://github.com/radbas/container/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Johannes Rabausch](https://github.com/jrabausch) - creator and maintainer
