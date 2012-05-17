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
  scope :excluded, lambda { |*ids| where("id NOT IN (?)", [ids].flatten.compact)}

  cms_is_mirrored
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
