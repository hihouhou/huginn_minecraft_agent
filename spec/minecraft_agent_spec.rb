require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::MinecraftAgent do
  before(:each) do
    @valid_options = Agents::MinecraftAgent.new.default_options
    @checker = Agents::MinecraftAgent.new(:name => "MinecraftAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
