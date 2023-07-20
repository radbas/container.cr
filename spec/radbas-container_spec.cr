require "./spec_helper"

describe Radbas::Container do
  describe "#get" do
    it "can get self" do
      container = Container.new
      entry = container.get(Radbas::Container)
      entry.should eq container
    end
  end
end
