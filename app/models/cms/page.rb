# encoding: utf-8
class Cms::Page < Cms::Orm::Page

  cms_acts_as_tree :counter_cache => :children_count
  cms_is_categorized
  cms_is_mirrored
  cms_has_revisions_for :blocks_attributes

  # -- Callbacks ------------------------------------------------------------
  before_validation :assigns_label,
                    :assign_parent
  after_validation :escape_slug
  before_create :assign_position
  before_save :assign_full_path,
              :set_cached_content
  after_save  :sync_child_pages
  # Not valid in MongoMapper, we take care of this with other attributes.
  after_find :unescape_slug_and_path

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

  # Method to collect prevous state of blocks for revisions
  def blocks_attributes_was
    blocks_attributes(true)
  end

  def initialize(attrs = {})
    super.tap {
      assign_full_path
    }
  end

  def full_path=(value)
    self.escaped_full_path = "#{CGI::escape(value).gsub('%2F', '/')}".squeeze('/')
    @full_path_dirty = true
  end
  def full_path
    CGI::unescape(self.escaped_full_path)
  end
  def slug=(value)
    self.escaped_slug = CGI::escape(value)
  end
  def slug
    CGI::unescape(self.escaped_slug) if self.escaped_slug
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
    @escaped_full_path = self.parent ? "#{CGI::escape(self.parent.full_path).gsub('%2F', '/')}/#{self.escaped_slug}".squeeze('/') : '/'
    @full_path_dirty = true
  end

  # before_create
  def assign_position
    if self.parent.nil?
      self.position = 0
    else
      # Who knows why the fuck this doesn't work.
      #max = self.siblings.map(&:position).max
      max = Cms::Page.where( :parent_id => self.parent_id).all.map(&:position).max
      self.position = max ? max + 1 : 0
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
    @content_cache = self.content(true)
  end

  # Forcing re-saves for child pages so they can update full_paths
  def sync_child_pages
    if @full_path_dirty || escaped_full_path_changed?
      self.children.all.each { |p| p.save! }
      @full_path_dirty = false
    end
  end

  # Escape slug unless it's nonexistent (root)
  def escape_slug
    self.escaped_slug = CGI::escape(self.slug) unless self.slug.nil?
  end

  # Unescape the slug and full path back into their original forms unless they're nonexistent
  def unescape_slug_and_path
    self.slug = CGI::unescape(self.escaped_slug) unless self.slug.nil?
    self.full_path = CGI::unescape(self.escaped_full_path) unless self.full_path.nil?
  end

end
