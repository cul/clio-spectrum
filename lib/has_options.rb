module HasOptionsHash
  module HasOptions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_option
        validates_presence_of :name, :association_type
      end

      def has_options(options={})
        configuration = { :option_model => "Option", :association_name => :options}
        configuration.update(options) if options.is_a?(Hash)

        # association_name = configuration[:association_name].to_s
        association_name = configuration[:association_name].to_s
        singular_association = association_name.singularize
        option_model = configuration[:option_model]
        table_name = option_model.constantize.table_name
        has_many association_name.to_sym, :class_name => configuration[:option_model], :as => :entity, :dependent => :destroy, :conditions => { :association_type => association_name}

        accepts_nested_attributes_for association_name.to_sym, :reject_if => lambda { |a| a[:name].blank? }, :allow_destroy => true


        class_eval <<-EOV
          define_method "find_#{singular_association}_value" do |name|
            (opt = #{association_name}.find_by_name(name.to_s)) ? opt.value : nil    
          end

          define_method "find_#{singular_association}_values" do |name|
            #{association_name}.find_all_by_name(name.to_s).collect(&:value)
          end

          define_method "#{association_name}_hash" do
            option_hash = Hash.new {|h,k| h[k] = []}

            #{association_name}.each do |option|
              option_hash[option.name] << option.value.to_s
            end

            option_hash
          end

          define_method "#{association_name}_hash_interned" do
            result = #{association_name}_hash
            result.symbolize_keys!
            
            result.each_pair do |k,v|
              result[k] = nil if v.length == 0
              result[k] = v.first if v.length == 1
            end
          end
          
          define_method "set_#{singular_association}!" do |name, *values|
            name = name.to_s
            existing = #{association_name}.find_all_by_name(name)
            new_opts = []
            values.each do |value|
              if (match = existing.detect { |opt| opt.value == value})
                existing.delete(match)
                new_opts <<match
              else
                new_opts << #{association_name}.create!(:name => name, :value => value)
              end
            end
            
            existing.each { |opt| opt.destroy }
            
            return new_opts
          end
        EOV

      end
    end

  end
end

