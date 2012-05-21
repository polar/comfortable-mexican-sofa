require "rails/all"
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  require "mongo_mapper"

  if File.exist?(File.expand_path('/config/database.yml', Rails.root))
    db_config = YAML::load(File.read(File.expand_path('/config/database.yml', Rails.root)))
  else
    db_config = YAML::load(File.read(File.expand_path('../../database.yml', __FILE__)))
  end


  begin
    prefix = ComfortableMexicanSofa.config.database_config
    dbname = (prefix ? prefix + "_" : "") + "mongodb_#{Rails.env}"

    if ! db_config[dbname]
      dbname = (prefix ? prefix + "_" : "") + "#{Rails.env}"
    end
    if db_config[dbname]['adapter'] == "mongodb"
      config   = db_config[dbname]
      hostname = config['hostname'] || "localhost"
      port     = config['port'] ? config['port'].to_i : 27017

      MongoMapper.connection = Mongo::Connection.new(hostname, port)
      MongoMapper.database   = config['database']

      MongoMapper::Document.plugin(MongoMapper::Plugins::IdentityMap)
      if config['authenticate'] == true
        MongoMapper.database.authenticate(config['username'], config['password'])
      end
    end
  rescue => e
    puts "ERROR: Could not connect to MongoDB or read config: #{e}"
  end
end
