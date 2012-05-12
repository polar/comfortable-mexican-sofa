
module ComfortableMexicanSofa::MongoMapper

end

[   'mongo_mapper/acts_as_tree',
    'mongo_mapper/has_revisions',
    'mongo_mapper/is_mirrored',
    'mongo_mapper/is_categorized'
].each do |path|
  puts "Loading #{path}"
  require File.expand_path(path, File.dirname(__FILE__))
  puts "Loaded #{path}"
end