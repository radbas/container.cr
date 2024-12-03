require "./spec_helper"

describe Radbas::Container do
  describe "#get" do
    it "can get self" do
      container = TestContainer.new
      entry = container.get(Radbas::Container)
      entry.should eq container
    end

    it "resolves registered services" do
      container = TestContainer.new
      service = container.get(TestService)
      service.should be_a TestService
      service.priv.should be_a PrivateService
    end

    it "should throw on subclass get" do
      expect_raises Radbas::Container::SubClassAccessException do
        container = TestContainer.new
        container.get(SubService)
      end
    end

    it "should throw on circular reference" do
      expect_raises Radbas::Container::CircularReferenceException do
        container = TestContainer.new
        container.get(CircularService)
      end
    end
  end
end
