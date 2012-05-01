class Cms::Orm::ActiveRecord::Site < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_sites'
  
  # -- Relationships --------------------------------------------------------
  has_many :layouts,    :dependent => :delete_all
  has_many :pages,      :dependent => :delete_all
  has_many :snippets,   :dependent => :delete_all
  has_many :files,      :dependent => :destroy
  has_many :categories, :dependent => :delete_all

  # -- Scopes ---------------------------------------------------------------
  scope :mirrored, where(:is_mirrored => true)
  
end