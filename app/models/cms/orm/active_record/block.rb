class Cms::Orm::ActiveRecord::Block < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_blocks'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :page
  has_many :files,
    :autosave   => true,
    :dependent  => :destroy

end
