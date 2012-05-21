# encoding: utf-8
class Cms::Orm::ActiveRecord::Page < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized

  ComfortableMexicanSofa.establish_connection(self)

  attr_accessor :tags,
                :blocks_attributes_changed

  self.table_name = 'cms_pages'

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :layout, :class_name => "Cms::Layout"
  belongs_to :target_page, :class_name => 'Cms::Page'
  has_many :blocks, :class_name => "Cms::Block",
    :autosave   => true,
    :dependent  => :destroy


  # Need to specify the topmost class
  cms_acts_as_tree  :class_name => "Cms::Page", :counter_cache => :children_count
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

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_pages.position')
  scope :published, where(:is_published => true)
  scope :excluded, lambda { |*ids| where("id NOT IN (?)", [ids].flatten.compact)}

  # -- Mirrors --------------------------------------------------------------

  attr_accessor :is_mirrored

  after_save    :sync_mirror
  after_destroy :destroy_mirror

  # Mirrors of the object found on other sites
  def mirrors
    return [] unless self.site.is_mirrored?
    sites = Cms::Site.mirrored.all - [self.site]
    sites.collect do |site|
      site.pages.find_by_full_path(self.full_path)
    end.compact
  end

  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    sites = Cms::Site.mirrored.all - [self.site]
    sites.each do |site|
      page = site.pages.find_by_full_path(self.full_path_was || self.full_path) || site.pages.build

      parent = site.pages.find_by_full_path(self.parent.try(:full_path))
      layout = site.layouts.find_by_identifier(self.layout.identifier)

      # Need to use :parent with MongoMapper, as before save doesn't sync up assignment on :parent_id before before_save callbacks.
      page.attributes = {
          :slug   => self.slug,
          :label  => self.slug.blank? ? self.label : page.label,
          :parent => parent,
          :layout => layout
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
    self.blocks.collect do |block|
      # Processing Content will build new blocks without content (perhaps to be picked up later?)
      # In any case, we really don't want to be counting new blocks that
      # don't have any content.'
      if !block.new_record? || block.content
        block_attr = {}
        block_attr[:identifier] = block.identifier
        block_attr[:content]    = was ? block.content_was : block.content
        block_attr
      end

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
  #MongoMapper you cannot create or override methods that are keys. It fucks things up.
  #def full_path
  #  self.read_attribute(:full_path) || self.assign_full_path
  #end


  # Processing content will return rendered content and will populate
  # self.cms_tags with instances of CmsTag
  def content(force_reload = false)
    force_reload ||= self.content_dirty
    @content_cache = force_reload ? nil : read_attribute(:content_cache)
    self.content_cache = @content_cache || begin
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
    self.content_cache = value
    self.content_dirty = false
    self.content_cache
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

  def initialize(attrs = {}, *args)
    super.tap {
      assign_full_path
    }
  end

  #def escaped_full_path_dirty
  #  self.escaped_full_path_dirty
  #end
  #
  #def escaped_full_path_was
  #  "#{CGI::escape(self.full_path_was).gsub('%2F', '/')}".squeeze('/') if self.escaped_full_path_was
  #end
  #
  #def escaped_full_path=(value)
  #  self.escaped_full_path = "#{CGI::escape(value).gsub('%2F', '/')}".squeeze('/')
  #end

  def escaped_full_path
    "#{CGI::escape(self.full_path).gsub('%2F', '/')}".squeeze('/') if self.full_path
  end

  #def escaped_slug_dirty
  #  self.slug_dirty
  #end

  #def escaped_slug_was
  #  CGI::escape(self.slug_was) if self.slug_was
  #end
  #
  #def escaped_slug=(value)
  #  self.slug = CGI::unescape(value) if value
  #end

  def escaped_slug
    "#{CGI::escape(self.slug).gsub('%2F', '/')}".squeeze('/') if self.slug
  end

  protected

  def assigns_label
    self.label = self.label.blank?? self.slug.try(:titleize) : self.label
  end

  def assign_parent
    return unless site
    self.parent ||= site.pages.roots.first unless self == site.pages.roots.first || site.pages.count == 0
  end

  def assign_full_path
    #self.escaped_full_path = self.parent ? "#{self.parent.escaped_full_path}/#{self.escaped_slug}".squeeze('/') : '/'
    #self.escaped_full_path
    self.full_path = self.parent ? "#{self.parent.full_path}/#{self.slug}".squeeze('/') : '/'
    self.full_path
  end

  # before_create
  def assign_position
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

  def validate_target_page
    return unless self.target_page
    p = self
    while p.target_page do
      return self.errors.add(:target_page_id, 'Invalid Redirect') if (p = p.target_page) == self
    end
  end

  # NOTE: This can create 'phantom' page blocks as they are defined in the layout. This is normal.
  def set_cached_content
    self.content_cache = self.content(true)
  end

  # Forcing re-saves for child pages so they can update full_paths
  def sync_child_pages
    self.children.all.each { |p| p.save! }
  end
end
