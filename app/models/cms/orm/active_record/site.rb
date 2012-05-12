class Cms::Orm::ActiveRecord::Site < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_sites'
  
  # -- Relationships --------------------------------------------------------
  has_many :layouts,    :class_name => "Cms::Layout", :dependent => :delete_all
  has_many :pages,      :class_name => "Cms::Page", :dependent => :delete_all
  has_many :snippets,   :class_name => "Cms::Snippet", :dependent => :delete_all
  has_many :files,      :class_name => "Cms::File", :dependent => :destroy
  has_many :categories, :class_name => "Cms::Category", :dependent => :delete_all

  # -- Scopes ---------------------------------------------------------------
  scope :mirrored, where(:is_mirrored => true)

  # When site is marked as a mirror we need to sync its structure
  # with other mirrors.
  def sync_mirrors
    return unless is_mirrored_changed? && is_mirrored?

    [self, Cms::Site.mirrored.where("id != #{id}").first].compact.each do |site|
      (site.layouts(:reload).roots + site.layouts.roots.map(&:descendants)).flatten.map(&:sync_mirror)
      (site.pages(:reload).roots + site.pages.roots.map(&:descendants)).flatten.map(&:sync_mirror)
      site.snippets(:reload).map(&:sync_mirror)
    end
  end
end