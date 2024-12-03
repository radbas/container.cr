require "spec"
require "../src/radbas-container"

class TestService
  getter priv

  def initialize(
    @priv : PrivateService,
    @auto : TestModule::AutoService
  ); end
end

class SubService < TestService; end

class PrivateService; end

module TestModule
  class AutoService; end
end

class CircularService; end

class TestContainer < Radbas::Container
  autowire(TestModule)
  register(TestService, public: true)
  register(PrivateService)
  register(CircularService, factory: ->{
    get(CircularService)
  }, public: true)
end
