
module ComfortableMexicanSofa::ActiveRecord

end

[   'active_record/acts_as_tree',
    'active_record/has_revisions',
    'active_record/is_mirrored',
    'active_record/is_categorized'
].each do |path|
  puts "Loading #{path}"
  require File.expand_path(path, File.dirname(__FILE__))
  puts "Loaded #{path}"
end