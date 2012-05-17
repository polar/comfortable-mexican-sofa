# This extension is needed so that arrays that seem like MongoMapper Associations
# can be treated the same.
class Array
  def all
    self
  end
end