class Cms::Orm::ActiveRecord::Layout < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_layouts'

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  has_many :pages, :class_name => "Cms::Page", :dependent => :nullify

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_layouts.position')
end
