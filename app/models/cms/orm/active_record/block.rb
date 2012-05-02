class Cms::Orm::ActiveRecord::Block < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)

  self.table_name = 'cms_blocks'

  # -- Relationships --------------------------------------------------------
  belongs_to :page, :class_name => "Cms::Page"
  has_many :files, :class_name => "Cms::File",
           :autosave           => true,
           :dependent          => :destroy

end
