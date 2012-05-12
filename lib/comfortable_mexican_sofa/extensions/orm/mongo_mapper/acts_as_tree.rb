module ComfortableMexicanSofa::MongoMapper::ActsAsTree

  #include MongoMapper::Plugins::ActsAsTree

  def self.included(base)
    puts "Including on #{base}"
    base.extend(ClassMethods)
    puts "Extended on #{base}"
  end
  
  module ClassMethods
    def cms_acts_as_tree(options = {})
      puts "MongoMapper::Acts as Tree! '#{name}'  '#{self.name}' #{self.superclass.superclass.name}"
      configuration = {
        :foreign_key    => 'parent_id', 
        :order          => nil, 
        :counter_cache  => nil,
        :dependent      => :destroy,
        :touch          => false }
      configuration.update(options) if options.is_a?(Hash)

      key configuration[:foreign_key], ObjectId unless keys.key?(configuration[:foreign_key])
      key configuration[:foreign_key].to_s.pluralize.to_sym, Array unless keys.key?(configuration[:foreign_key].to_s.pluralize.to_sym)

      belongs_to :parent,
                 :class_name => name,
                 :foreign_key => configuration[:foreign_key]

      many :children,
           :class_name     => name,
           :foreign_key    => configuration[:foreign_key],
           :order          => configuration[:order],
           :dependent      => configuration[:dependent] do
        def roots
          where(configuration[:foreign_key] => nil)
        end
      end

      before_save :set_parents

      #key configuration[:counter_cache], Integer, :default => 0, :null => false if configuration[:counter_cache]

      #before_save "update_#{configuration[:counter_cache]}" if configuration[:counter_cache]


      class_eval <<-EOV
        include ComfortableMexicanSofa::MongoMapper::ActsAsTree::InstanceMethods

        puts "Setting up Roots"
        scope :roots,  where("#{configuration[:foreign_key]}" => nil).order("#{configuration[:order]}")

        def #{configuration[:counter_cache]||'children_count'}
          children.count
        end


            def self.root
              where("#{configuration[:foreign_key]}".to_sym => nil).sort("#{configuration[:order]}").first
            end

            def set_parents
              self.#{configuration[:foreign_key].to_s.pluralize} = parent.#{configuration[:foreign_key].to_s.pluralize}.dup << #{configuration[:foreign_key]} if parent?
            end

            def ancestors
              self.class.where(:id => { '$in' => self.#{configuration[:foreign_key].to_s.pluralize} }).all.reverse || []
            end

            def root
              self.class.find(self.#{configuration[:foreign_key].to_s.pluralize}.first) || self
            end

            def descendants
              self.class.where('#{configuration[:foreign_key].to_s.pluralize}' => self.id).all
            end

            def depth
              self.#{configuration[:foreign_key].to_s.pluralize}.count
            end


        validates_each "#{configuration[:foreign_key]}" do |record, attr, value|
          if value
            if record.id == value
              record.errors.add attr, "cannot be it's own id"
            elsif record.descendants.map {|c| c.id}.include?(value)
              record.errors.add attr, "cannot be a descendant's id"
            end
          end
        end
      EOV
      
    end
  end
  
  module InstanceMethods

    def root?
      !self.parent_id
    end

    # Returns all siblings of the current node.
    #
    #   subchild1.siblings # => [subchild2]
    def siblings
      self_and_siblings - [self]
    end
    
    # Returns all siblings and a reference to the current node.
    #
    #   subchild1.self_and_siblings # => [subchild1, subchild2]
    def self_and_siblings
      parent ? parent.children : self.class.roots.all
    end
  end
end