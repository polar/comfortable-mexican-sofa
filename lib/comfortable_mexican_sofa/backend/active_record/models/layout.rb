class Cms::Orm::ActiveRecord::Layout < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions

  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_layouts'

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  has_many :pages, :class_name => "Cms::Page", :dependent => :nullify

  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_layouts.position')
  scope :excluded, lambda { |*ids| where("id NOT IN (?)", [ids].flatten.compact)}

  # Need to specify the topmost class
  cms_acts_as_tree  :class_name => "Cms::Layout"
  cms_has_revisions_for :content, :css, :js

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


  # -- Class Methods --------------------------------------------------------
  # Tree-like structure for layouts
  def self.options_for_select(site, layout = nil, current_layout = nil, depth = 0, spacer = '. . ')
    out = []

    [current_layout || site.layouts.roots.all].flatten.each do |l|
      next if layout == l
      out << [ "#{spacer*depth}#{l.label}", l.id ]
      l.children.all.each do |child|
        out += options_for_select(site, layout, child, depth + 1, spacer)
      end
    end
    return out.compact
  end

  # List of available application layouts
  def self.app_layouts_for_select
    Dir.glob(File.expand_path('app/views/layouts/**/*.html.*', Rails.root)).collect do |filename|
      filename.gsub!("#{File.expand_path('app/views/layouts', Rails.root)}/", '')
      filename.split('/').last[0...1] == '_' ? nil : filename.split('.').first
    end.compact.sort
  end

  # -- Mirrors --------------------------------------------------------------

  attr_accessor :is_mirrored

  after_save    :sync_mirror
  after_destroy :destroy_mirror

  # Mirrors of the object found on other sites
  def mirrors
    return [] unless self.site.is_mirrored?
    sites = Cms::Site.mirrored.all - [self.site]
    sites.collect do |site|
      site.layouts.find_by_identifier(self.identifier)
    end.compact
  end

  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    sites = Cms::Site.mirrored.all - [self.site]
    sites.each do |site|
      layout = site.layouts.find_by_identifier(self.identifier_was || self.identifier) || site.layouts.build

      layout.attributes  = {
          :identifier => self.identifier,
          :parent_id  => site.layouts.find_by_identifier(self.parent.try(:identifier)).try(:id)
      }

      layout.is_mirrored = true
      layout.save
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
  # -- Instance Methods -----------------------------------------------------
  # magical merging tag is {cms:page:content} If parent layout has this tag
  # defined its content will be merged. If no such tag found, parent content
  # is ignored.
  def merged_content
    if parent
      regex = /\{\{\s*cms:page:content:?(?:(?::text)|(?::rich_text))?\s*\}\}/
      if parent.merged_content.match(regex)
        parent.merged_content.gsub(regex, content.to_s)
      else
        content.to_s
      end
    else
      content.to_s
    end
  end

  protected

  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  # before create
  def assign_position
    #max = self.site.layouts.where(:parent_id => self.parent_id).all.reduce(0) { |m,l| m < l.position ? l.position : m }
    # Who knows why the fuck this doesn't work.
    #max = self.siblings.map(&:position).max
    max = Cms::Layout.where(:parent_id => self.parent_id).all.map(&:position).max
    self.position = max ? max + 1 : 0
  end

  # Forcing page content reload
  def clear_cached_page_content
    #if this happens as a result of an autosave in MongoMapper, it will not work because
    # the page will be invalid, trying to save the layout.
    #self.pages.each{ |page| page.save! }
    self.pages.all.each{ |page| page.save! }
    self.children.all.each{ |child_layout| child_layout.clear_cached_page_content }
  end

end
