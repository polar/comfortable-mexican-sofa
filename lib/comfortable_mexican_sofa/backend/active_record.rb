module ComfortableMexicanSofa::ActiveRecord
end
module Cms
  module Orm
    module ActiveRecord
    end
  end
end

[   'active_record/extensions/acts_as_tree',
    'active_record/extensions/has_revisions',
    'active_record/extensions/is_categorized',
    'active_record/models/block',
    'active_record/models/categorization',
    'active_record/models/category',
    'active_record/models/file',
    'active_record/models/layout',
    'active_record/models/page',
    'active_record/models/revision',
    'active_record/models/site',
    'active_record/models/snippet',
].each do |path|
  require File.expand_path(path, File.dirname(__FILE__))
end