class Cms::Category < Cms::Orm::Category
    
  # -- Validations ----------------------------------------------------------
  validates :site_id, 
    :presence   => true
  validates :label,
    :presence   => true,
    :uniqueness => { :scope => [:categorized_type, :site_id] }
  validates :categorized_type,
    :presence   => true

  
end
