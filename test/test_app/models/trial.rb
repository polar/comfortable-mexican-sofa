class Trial
  extend ActiveModel::Serialization
  def hello
    @attributes[:hello]
  end

  attr_accessor :attributes
  def initialize(attributes)
    @attributes = attributes
  end
end