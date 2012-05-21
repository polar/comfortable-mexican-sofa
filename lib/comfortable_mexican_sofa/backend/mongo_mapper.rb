module ComfortableMexicanSofa::MongoMapper
end
module Cms
  module Orm
    module MongoMapper
    end
  end
end

[   'mongo_mapper/extensions/acts_as_tree',
    'mongo_mapper/extensions/has_revisions',
    'mongo_mapper/extensions/is_categorized',
    'mongo_mapper/models/block',
    'mongo_mapper/models/categorization',
    'mongo_mapper/models/category',
    'mongo_mapper/models/file',
    'mongo_mapper/models/layout',
    'mongo_mapper/models/page',
    'mongo_mapper/models/revision',
    'mongo_mapper/models/site',
    'mongo_mapper/models/snippet',
].each do |path|
  require File.expand_path(path, File.dirname(__FILE__))
end