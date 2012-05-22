class Cms::Orm::ActiveRecord::Snippet < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_snippets'

  attr_accessible :label, :identifier, :content, :position, :is_shared
  attr_accessible :site, :site_id

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_snippets.position')
  scope :excluded, lambda { |*ids| where("id NOT IN (?)", [ids].flatten.compact)}

  cms_is_categorized
  cms_has_revisions_for :content

  # -- Callbacks ------------------------------------------------------------
  before_validation :assign_label
  before_create :assign_position
  after_save    :clear_cached_page_content
  after_destroy :clear_cached_page_content

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            :presence   => true
  validates :label,
            :presence   => true
  validates :identifier,
            :presence   => true,
            :uniqueness => { :scope => :site_id },
            :format     => { :with => /^\w[a-z0-9_-]*$/i }


  # -- Mirror ---------------------------------------------------------------

  # This attribute is used to stop the recursive update in sync_mirror
  # TODO: Fix when it should be cleared.
  attr_accessor :is_mirrored

  after_save    :sync_mirror
  after_destroy :destroy_mirror

  # Mirrors of the Snippet found on other sites
  def mirrors
    return [] unless self.site.is_mirrored?
    sites = Cms::Site.mirrored.all - [self.site]
    sites.collect do |site|
      site.snippets.find_by_identifier(self.identifier)
    end.compact
  end

  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    sites = Cms::Site.mirrored.all - [self.site]
    sites.each do |site|
      snippet = site.snippets.find_by_identifier(self.identifier_was || self.identifier) || site.snippets.build

      snippet.attributes = {
          :identifier => self.identifier
      }

      # This will stop sync_mirror being called in the after_save callback for this instance.
      snippet.is_mirrored = true
      snippet.save
    end
  end

  # Mirrors will be destroyed on after_destroy
  def destroy_mirror
    return if self.is_mirrored || !self.site.is_mirrored?
    mirrors.each do |mirror|
      mirror.is_mirrored = true
      mirror.destroy
    end
  end

  protected

  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  # Note: This might be slow. We have no idea where the snippet is used, so
  # gotta reload every single page. Kinda sucks, but might be ok unless there
  # are hundreds of pages.
  def clear_cached_page_content
    site.pages.all.each do |p|
      Cms::Page.where(:id => p.id).all.each do |p|
        p.update_attributes(:content => p.content(true))
      end
    end
  end

  def assign_position
    # Processing Content will generate new ones, However in MongoMapper.
    # map seems to grab them. So, we set the default position to -1.
    max = self.site.snippets.map(&:position).max
    self.position = max ? max + 1 : 0
  end

end
