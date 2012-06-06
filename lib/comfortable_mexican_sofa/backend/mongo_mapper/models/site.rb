class Cms::Orm::MongoMapper::Site
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :label, String, :null => false
  key :identifier, String, :null => false
  key :hostname, String, :null => false
  key :path, String, :default => ""
  key :locale, String, :default => "en", :null => false
  key :is_mirrored, Boolean, :default => false, :null => false

  attr_accessible :label, :identifier, :hostname, :path, :locale, :is_mirrored

  # -- Relationships --------------------------------------------------------

  many :layouts,    :class_name => "Cms::Layout", :autosave => true, :dependent => :delete_all do
    def roots
      where(:parent_id => nil)
    end

    def excluded(*ids)
      if (ids = [ids].flatten.compact).present?
        where(:id.nin => ids)
      else
        where()
      end
    end
  end

  many :pages,      :class_name => "Cms::Page", :autosave => true, :dependent => :delete_all do
    def roots
      where(:parent_id => nil)
    end

    def root
      where(:parent_id => nil).first
    end

    def categorized(*categories)
      if (categories = [categories].flatten.compact).present?
        cats = Cms::Category.where(:label.in => categories).all
        catz = Cms::Categorization.where(:category_id.in => cats.map {|c|c.id}).all
        pages = catz.select {|c| c.categorized_type == Cms::Page.name }.map {|c|c.categorized}
        where(:id.in => pages.map {|c|c.id})
      else
        where()
      end
    end

    def excluded(*ids)
      if (ids = [ids].flatten.compact).present?
        where(:id.nin => ids)
      else
        where()
      end
    end

    def published
      where(:is_published => true)
    end
  end

  many :snippets,   :class_name => "Cms::Snippet", :autosave => true, :dependent => :delete_all do
    def by_position
      order(:position)
    end

    def categorized(*categories)
      if (categories = [categories].flatten.compact).present?
        cats = Cms::Category.where(:label.in => categories).all
        catz = Cms::Categorization.where(:category_id.in => cats.map {|c|c.id}).all
        snips = catz.select {|c| c.categorized_type == Cms::Snippet.name }.map {|c|c.categorized}
        where(:id.in => snips.map {|c|c.id})
      else
        where()
      end
    end

    def excluded(*ids)
      if (ids = [ids].flatten.compact).present?
        where(:id.nin => ids)
      else
        where()
      end
    end
  end

  many :files,      :class_name => "Cms::File", :autosave => true, :dependent => :destroy   do
    def images
      where(:file_content_type => Cms::File::IMAGE_MIMETYPES)
    end

    def not_images
      where(:file_content_type.nin() =>  Cms::File::IMAGE_MIMETYPES)
    end

    def categorized(*categories)
      if (categories = [categories].flatten.compact).present?
        cats = Cms::Category.where(:label.in => categories).all
        catz = Cms::Categorization.where(:category_id.in => cats.map {|c|c.id}).all
        files = catz.select {|c| c.categorized_type == Cms::File.name }.map {|c|c.categorized}
        where(:id.in => files.map {|c|c.id})
      else
        where()
      end
    end
  end

  many :categories, :class_name => "Cms::Category", :autosave => true, :dependent => :delete_all do
    def by_type(type)
      where(:categorized_type => type)
    end
  end


  # -- Scopes ---------------------------------------------------------------

  scope :mirrored, where(:is_mirrored => true)


  # -- Callbacks ------------------------------------------------------------

  before_validation :assign_identifier,
                    :assign_label
  before_save :clean_path
  after_save  :sync_mirrors

  # -- Validations ----------------------------------------------------------

  validates :identifier,
            :presence   => true,
            :uniqueness => true,
            :format     => { :with => /^\w[a-z0-9_-]*$/i }
  validates :label,
            :presence   => true
  validates :hostname,
            :presence   => true,
            :uniqueness => { :scope => :path },
            :format     => { :with => /^[\w\.\-]+(:[0-9]+)?$/ }

  # -- Class Methods --------------------------------------------------------

  # Return the Cms::Site instance based on host and path
  def self.find_site(host, path = nil)
    return Cms::Site.first if Cms::Site.count == 1
    # TODO: Do we have to unescape here?
    path = path.squeeze("/") unless path.nil?
    cms_site = nil
    Cms::Site.find_all_by_hostname(real_host_from_aliases(host)).each do |site|
      if site.path.blank?
        cms_site = site
      elsif "#{path}/".match /^\/#{Regexp.escape(site.path.to_s)}\//
        cms_site = site
        break
      end
    end
    return cms_site
  end

  protected

  # When site is marked as a mirror we need to sync its structure
  # with the other mirrors.
  def sync_mirrors
    return unless is_mirrored_changed? && is_mirrored?

    sites = [self, Cms::Site.mirrored.where(:id.ne => id).first].compact
    # We must do all layouts first because the newly built pages need them.
    # We must do all pages before snippets because the newly built snippets need them.
    sites.each do |site|
      (site.layouts.where(:parent_id => nil).all + site.layouts.where(:parent_id => nil).all.map(&:descendants)).flatten.map(&:sync_mirror)
    end
    sites.each do |site|
      (site.pages.where(:parent_id => nil).all + site.pages.where(:parent_id => nil).all.map(&:descendants)).flatten.map(&:sync_mirror)
    end
    sites.each do |site|
      site.snippets.map(&:sync_mirror)
    end
  end


  def self.real_host_from_aliases(host)
    if aliases = ComfortableMexicanSofa.config.hostname_aliases
      aliases.each do |alias_host, aliases|
        return alias_host if aliases.include?(host)
      end
    end
    host
  end

  def assign_identifier
    self.identifier = self.identifier.blank?? self.hostname.try(:idify) : self.identifier
  end

  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  def clean_path
    self.path ||= ''
    self.path.squeeze!('/')
    self.path.gsub!(/\/$/, '')
  end

end