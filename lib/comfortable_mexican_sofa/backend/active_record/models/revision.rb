class Cms::Orm::ActiveRecord::Revision < ActiveRecord::Base

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_revisions'
  # -- Relationships --------------------------------------------------------
  belongs_to :record, :polymorphic => true

  serialize :data

  # -- Scopes ---------------------------------------------------------------
  default_scope order('created_at DESC')
  
end