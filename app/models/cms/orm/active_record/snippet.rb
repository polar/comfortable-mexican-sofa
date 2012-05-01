class Cms::Orm::ActiveRecord::Snippet < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_snippets'

  cms_is_categorized
  cms_is_mirrored
  cms_has_revisions_for :content

  # -- Relationships --------------------------------------------------------
  belongs_to :site

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_snippets.position')

  
end
