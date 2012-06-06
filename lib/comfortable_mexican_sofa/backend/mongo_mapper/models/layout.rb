class Cms::Orm::MongoMapper::Layout
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized

  key :app_layout, String
  key :label, String, :null => false
  key :identifier, String, :null => false
  key :content, String
  key :css, String
  key :js, String
  key :position, Integer, :default => -1, :null => false
  key :is_shared, Boolean, :default => false, :null => false

  timestamps!

  cms_is_categorized  :class_name => "Cms::Layout"
  cms_acts_as_tree :class_name => "Cms::Layout"
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


  # -- Associations --------------------------------------------------------

  belongs_to :site, :class_name => "Cms::Site"

  many :pages, :class_name => "Cms::Page", :dependent => :nullify

  attr_accessible :app_layout, :label, :identifier, :content, :css, :js, :position, :is_shared
  attr_accessible :site, :site_id

  # -- Mirror ---------------------------------------------------------------

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
      begin
        layout.save!
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

  # -- Scopes ---------------------------------------------------------------
  #default_scope order(:position)
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

  # before_validation :assign_label
  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  # before_create :assign_position
  def assign_position
    #max = self.site.layouts.where(:parent_id => self.parent_id).all.reduce(0) { |m,l| m < l.position ? l.position : m }
    # Who knows why the fuck this doesn't work.
    #max = self.siblings.map(&:position).max
    max = Cms::Layout.where(:parent_id => self.parent_id).all.map(&:position).max
    self.position = max ? max + 1 : 0
  end

  # after_save    :clear_cached_page_content
  # after_destroy :clear_cached_page_content
  # Forcing page content reload
  def clear_cached_page_content
    #if this happens as a result of an autosave in MongoMapper, it will not work because
    # the page will be invalid, trying to save the layout.
    #self.pages.each{ |page| page.save! }
    self.pages.all.each{ |page| page.reload }
    self.children.all.each{ |child_layout| child_layout.clear_cached_page_content }
  end

end