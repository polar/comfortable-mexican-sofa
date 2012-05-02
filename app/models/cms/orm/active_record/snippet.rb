class Cms::Orm::ActiveRecord::Snippet < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_snippets'

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_snippets.position')
end
