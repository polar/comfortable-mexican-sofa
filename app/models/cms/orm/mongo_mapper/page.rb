class Cms::Orm::MongoMapper::Page
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized

  key :label, String, :null => false
  key :escaped_slug, String
  key :escaped_full_path, String, :null => false
  #TODO: Change this in AR
  key :content_dirty, Boolean, :default => true
  key :content_cache, String
  key :position, Integer, :default => -1, :null => false
  key :is_published, Boolean, :default => true, :null => false
  key :is_shared, Boolean, :default => false, :null => false

  timestamps!

  # -- Associations --------------------------------------------------------

  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :layout, :class_name => "Cms::Layout"
  belongs_to :target_page, :class_name => 'Cms::Page'

  many :blocks, :class_name => "Cms::Block",
           :autosave   => true,
           :dependent  => :destroy

  attr_accessible :full_path, :escaped_full_path
  attr_accessible :label, :slug, :escaped_slug, :content, :position, :children_count, :is_published, :is_shared
  attr_accessible :site, :site_id
  attr_accessible :layout, :layout_id
  attr_accessible :parent, :parent_id
  attr_accessible :target_page, :target_page_id

  # -- Scopes ---------------------------------------------------------------
  #default_scope order(:position)
  scope :published, where(:is_published => true)

  # -- Non-persistent attributes

  attr_accessible :blocks_attributes
  attr_accessor :tags,
                :blocks_attributes_changed

  cms_acts_as_tree :class_name => "Cms::Page", :counter_cache => :children_count
  cms_is_categorized
  cms_has_revisions_for :blocks_attributes

  # -- Callbacks ------------------------------------------------------------
  before_validation :assigns_label,
                    :assign_parent
  before_create :assign_position
  before_save :assign_full_path,
              :set_cached_content
  after_save  :sync_child_pages

  # -- Validations ----------------------------------------------------------

  validates :site_id,
            :presence   => true
  validates :label,
            :presence   => true
  validates :slug,
            :presence   => true,
            :format     => /^\p{Alnum}[\.\p{Alnum}_-]*$/i,
            :uniqueness => { :scope => :parent_id },
            :unless     => lambda{ |p| p.site && (p.site.pages.count == 0 || p.site.pages.roots.first == self) }
  validates :layout,
            :presence   => true
  validate :validate_target_page

  # -- Mirrors --------------------------------------------------------------

  attr_accessor :is_mirrored

  after_save    :sync_mirror
  after_destroy :destroy_mirror

  # Mirrors of the object found on other sites
  def mirrors
    return [] unless self.site.is_mirrored?
    sites = Cms::Site.mirrored.all - [self.site]
    sites.collect do |site|
      site.pages.find_by_escaped_full_path(self.escaped_full_path)
    end.compact
  end

  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    sites = Cms::Site.mirrored.all - [self.site]
    sites.each do |site|
      page = site.pages.find_by_escaped_full_path(self.escaped_full_path_was || self.escaped_full_path) || site.pages.build

      parent = site.pages.find_by_escaped_full_path(self.parent.try(:escaped_full_path))
      layout = site.layouts.find_by_identifier(self.layout.identifier)

      # Need to use :parent with MongoMapper, as before save doesn't sync up assignment on :parent_id before before_save callbacks.
      page.attributes = {
          :escaped_slug => self.escaped_slug,
          :label        => self.slug.blank? ? self.label : page.label,
          :parent       => parent,
          :layout       => layout
      }

      page.is_mirrored = true
      page.save
    end
  end

  # Mirrors should be destroyed
  def destroy_mirror
    return if self.is_mirrored || !self.site.is_mirrored?
    mirrors.each do |mirror|
      mirror.is_mirrored = true
      mirror.destroy
    end
  end

  # Transforms existing cms_block information into a hash that can be used
  # during form processing. That's the only way to modify cms_blocks.
  def blocks_attributes(was = false)
    self.blocks.all.collect do |block|
        block_attr = {}
        block_attr[:identifier] = block.identifier
        block_attr[:content]    = was ? block.content_was : block.content
        block_attr
    end
  end

  # Array of block hashes in the following format:
  #   [
  #     { :identifier => 'block_1', :content => 'block content' },
  #     { :identifier => 'block_2', :content => 'block content' }
  #   ]
  def blocks_attributes=(block_hashes = [])
    block_hashes = block_hashes.values if block_hashes.is_a?(Hash)
    block_hashes.each do |block_hash|
      block_hash.symbolize_keys! unless block_hash.is_a?(HashWithIndifferentAccess)
      block =
          self.blocks.detect{|b| b.identifier == block_hash[:identifier]} ||
              self.blocks.build(:identifier => block_hash[:identifier])
      block.content = block_hash[:content]
      self.blocks_attributes_changed = self.blocks_attributes_changed || block.content_changed?
    end
  end


  # -- Class Methods --------------------------------------------------------

  # Tree-like structure for pages
  def self.options_for_select(site, page = nil, current_page = nil, depth = 0, exclude_self = true, spacer = '. . ')
    return [] if (current_page ||= site.pages.roots.first) == page && exclude_self || !current_page
    out = []
    out << [ "#{spacer*depth}#{current_page.label}", current_page.id ] unless current_page == page
    current_page.children.each do |child|
      out += options_for_select(site, page, child, depth + 1, exclude_self, spacer)
    end
    return out.compact
  end

  # -- Instance Methods -----------------------------------------------------
  ## For previewing purposes sometimes we need to have full_path set
  #MongoMapper you cannot create or override methods that are keys that are assigned by save callbacks. It
  #screws things up. Stop with the "magic", already.
  #
  #def full_path
  #  self.read_attribute(:full_path) || self.assign_full_path
  #end

  # Processing content will return rendered content and will populate
  # self.tags with instances of CmsTag
  def content(force_reload = false)
    force_reload ||= @content_dirty
    @content_cache = force_reload ? nil : read_attribute(:content_cache)
    @content_cache ||= begin
      self.tags = [] # resetting
      if layout
        ComfortableMexicanSofa::Tag.process_content(
            self,
            ComfortableMexicanSofa::Tag.sanitize_irb(layout.merged_content)
        )
      else
        ''
      end
    end
  end

  def content=(value)
    @content_cache = value
    @content_dirty = false
    @content_cache
  end

  # Array of cms_tags for a page. Content generation is called if forced.
  # These also include initialized cms_blocks if present
  def tags(force_reload = false)
    self.content(true) if force_reload
    @tags ||= []
  end

  # Full url for a page
  def url
    "http://#{self.site.hostname}#{self.full_path}"
  end

  # Method to collect previous state of blocks for revisions
  def blocks_attributes_was
    blocks_attributes(true)
  end

  def initialize(attrs = {})
    super.tap {
      assign_full_path
    }
  end

  #
  # We have convenience methods to convert between escaped and unescaped slugs and full_paths
  #
  def full_path_dirty
    self.escaped_full_path_dirty
  end

  def full_path_was
    CGI::unescape(self.escaped_full_path_was) if self.escaped_full_path_was
  end

  def full_path=(value)
    self.escaped_full_path = "#{CGI::escape(value).gsub('%2F', '/')}".squeeze('/')
  end

  def full_path
    CGI::unescape(self.escaped_full_path) if self.escaped_full_path
  end

  def slug_dirty
    self.escaped_slug_dirty
  end

  def slug_was
    CGI::unescape(self.escaped_slug_was) if self.escaped_slug_was
  end

  def slug=(value)
    self.escaped_slug = CGI::escape(value) if value
  end

  def slug
    CGI::unescape(self.escaped_slug) if self.escaped_slug
  end

  protected

  # before_validation :assign_label
  def assigns_label
    self.label = self.label.blank?? self.slug.try(:titleize) : self.label
  end

  # before_validation :assign_parent
  def assign_parent
    return unless site
    self.parent ||= site.pages.roots.first unless self == site.pages.roots.first || site.pages.count == 0
  end

  # before_save :assign_full_path
  def assign_full_path
    self.escaped_full_path = self.parent ? "#{self.parent.escaped_full_path}/#{self.escaped_slug}".squeeze('/') : '/'
  end

  # before_create :assign_position
  def assign_position
    # We bank on default == -1 on create.
    if self.position == -1
      if self.parent.nil?
        self.position = 0
      else
        # Who knows why the fuck this doesn't work.
        #max = self.siblings.map(&:position).max
        max = Cms::Page.where( :parent_id => self.parent_id).all.map(&:position).max
        self.position = max ? max + 1 : 0
      end
    end
  end

  # validate :validate_target_page
  def validate_target_page
    return unless self.target_page
    p = self
    while p.target_page do
      return self.errors.add(:target_page_id, 'Invalid Redirect') if (p = p.target_page) == self
    end
  end

  # before_save :set_cached_content
  # NOTE: This can create 'phantom' page blocks as they are defined in the layout. This is normal.
  def set_cached_content
    @content_cache = self.content(true)
  end

  # after_save  :sync_child_pages
  # Forcing re-saves for child pages so they can update full_paths
  def sync_child_pages
    if @full_path_dirty || escaped_full_path_changed?
      self.children.all.each { |p| p.save! }
      @full_path_dirty = false
    end
  end
end