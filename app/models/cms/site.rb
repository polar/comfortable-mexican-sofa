class Cms::Site < Cms::Orm::Site

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
    :format     => { :with => /^[\w\.\-]+$/ }

  
  # -- Class Methods --------------------------------------------------------
  # returning the Cms::Site instance based on host and path
  def self.find_site(host, path = nil)
    return Cms::Site.first if Cms::Site.count == 1
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

  # sync_mirrors is defined in the particular Orm superclass.
  
end