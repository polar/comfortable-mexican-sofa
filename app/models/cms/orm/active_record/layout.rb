class Cms::Orm::ActiveRecord::Layout < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  puts "Loading Class #{self.name} and acts as tree"
  cms_acts_as_tree
  puts "Done Class #{self.name} and acts as tree"
  cms_is_mirrored
  cms_has_revisions_for :content, :css, :js

  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_layouts'

  # -- Relationships --------------------------------------------------------
  belongs_to :site
  has_many :pages, :dependent => :nullify

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_layouts.position')
end
