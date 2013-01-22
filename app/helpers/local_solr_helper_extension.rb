module LocalSolrHelperExtension
  extend ActiveSupport::Concern
  include Blacklight::SolrHelper



    ##
    # Convert a facet/value pair into a solr fq parameter
    def facet_value_to_fq_string(facet_field, value) 
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag


      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      fq = case
        when (facet_config and facet_config.query)
          facet_config.query[value][:fq]
        when (facet_config and facet_config.date),
             (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
             (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
          "#{prefix}#{facet_field}:#{value}"
        when value.is_a?(Range)
          "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
        when facet_field.to_s[0] == '-'
          "#{facet_field}:#{value}"
        else
          "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end


    end
end
