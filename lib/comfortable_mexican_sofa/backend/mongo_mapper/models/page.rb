class Cms::Orm::MongoMapper::Page
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized

  key :label, String, :null => false
  key :slug, String
  key :full_path, String, :null => false
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

  cms_acts_as_tree :class_name => "Cms::Page", :counter_cache => :children_count, :order => :position
  cms_is_categorized :class_name => "Cms::Page"
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
  # MongoMapper validations don't deal with UTF-8 strings.
  validates :slug,
            :presence   => true,
  #          :format     => /^\p{Alnum}[\.\p{Alnum}_-]*$/i,
            :uniqueness => { :scope => :parent_id },
            :unless     => lambda{ |p| p.site && (p.site.pages.count == 0 || p.site.pages.roots.first == self) }
  validate  :validate_slug_format
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
      site.pages.find_by_full_path(self.full_path)
    end.compact
  end

  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    sites = Cms::Site.mirrored.all - [self.site]
    sites.each do |site|
      page = site.pages.find_by_full_path(self.full_path_was || self.full_path) || site.pages.build

      parent = site.pages.find_by_full_path(self.parent.try(:full_path))
      layout = site.layouts.find_by_identifier(self.layout.try(:identifier))

      # Need to use :parent with MongoMapper, as before save doesn't sync up assignment on :parent_id before before_save callbacks.
      page.attributes = {
          :slug => self.slug,
          :label        => self.slug.blank? ? self.label : page.label,
          :parent       => parent,
          :layout       => layout
      }

      page.is_mirrored = true
      begin
        page.save!
      rescue MongoMapper::DocumentNotValid => boom
        ComfortableMexcianSofa.logger.detailed_error(boom)
      end
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
    current_page.children.all.each do |child|
      out += options_for_select(site, page, child, depth + 1, exclude_self, spacer)
    end
    return out.compact
  end

  # -- Instance Methods -----------------------------------------------------

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

  # This method renders the content of the page within the ActionView. It has access
  # to all controller variables, routes, and helpers, which allows the tags to render
  # in that context. You may render directly in an erb file like so:
  #   <%= page.render(self, :status => 200) %>
  # If the page layout has an app_layout content will be rendered in that layout.
  # Note, that in this situation, if you set a layout in your controller, it will render
  # this content within that layout. You should rendering the page with an empty layout.
  #
  def render(view, options)
    self.tags = [] # resetting
    if layout
      app_layout = (layout.app_layout.blank? || view.request.xhr?) ? false : layout.app_layout

      content = ComfortableMexicanSofa::Tag.render_in_view(
          self,
          view,
          ComfortableMexicanSofa::Tag.sanitize_irb(layout.merged_content)
      )
      options.merge!({   :inline => content,
                         :layout => (app_layout ? "layouts/#{app_layout}" : false)
                     })
      view.render options
    else
      ''
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
    "http://" + "#{self.site.hostname}/#{site.path}/#{self.full_path}".squeeze("/")
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

  def escaped_full_path
    "#{CGI::escape(self.full_path).gsub('%2F', '/')}".squeeze('/') if self.full_path
  end

  def escaped_slug
    "#{CGI::escape(self.slug)}" if self.slug
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
    self.full_path = self.parent ? "#{self.parent.full_path}/#{self.slug}".squeeze('/') : '/'
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

  def validate_slug_format
    pattern = '^\\p{Alnum}[\\.\\p{Alnum}_-]*$'

    if self.slug
      encoding = self.slug.encoding
      enc_rexp = Regexp.new(pattern.encode(encoding), Regexp::IGNORECASE)
      ret = enc_rexp.match(slug)
      if (!ret)
        self.errors.add(:slug, "is not valid format")
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
    if self.full_path_changed?
      self.children.all.each { |p| p.save! }
    end
  end

  # Can override
  def export_attributes()
    {}
  end

  # Can override
  def import_attributes(attributes)

  end
end
