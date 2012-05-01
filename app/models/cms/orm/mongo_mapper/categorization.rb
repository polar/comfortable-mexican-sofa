class Cms::Orm::MongoMapper::Categorization

#  self.table_name = 'cms_categorizations'

  # -- Relationships --------------------------------------------------------
  belongs_to :category
  belongs_to :categorized,
             :polymorphic => true

  attr_accessible :category, :category_id
  attr_accessbile :categorized, :categorized_id

end