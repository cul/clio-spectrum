module LocalSolrHelperExtension
  extend ActiveSupport::Concern
  include Blacklight::SolrHelper

  def is_advanced_search?(req_params = params)
    req_params[:search_field] == 'advanced' && req_params[:advanced].kind_of?(Hash)

  end

  def advanced_search_operator(req_params = params)
    advanced_operator = req_params[:advanced_operator] || "AND"
  end

  def advanced_search_queries(req_params = params)
    if req_params[:advanced].kind_of?(Hash)
      req_params[:advanced].reject { |k,v| v.to_s.empty? }
    else
      {}
    end
  end

  def add_advanced_search_to_solr(solr_parameters, req_params = params)
    if is_advanced_search?(req_params)
      solr_parameters[:qt] = req_params[:qt] if req_params[:qt]

      
      advanced_q = advanced_search_queries(req_params).collect do |field_name, value|
        search_field_def = search_field_def_for_key(field_name)

        if (search_field_def && hash = search_field_def.solr_local_parameters)
          local_params = hash.collect do |key, val|
            key.to_s + "=" + solr_param_quote(val, :quote => "'")
          end.join(" ")
          "_query_:\"{!dismax #{local_params}}#{value}\""
        else
          value.to_s
        end
        
      end


      solr_parameters[:q] = advanced_q.join(" #{advanced_search_operator(req_params)} ")
  
    end
  end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query. 
    def add_facet_fq_to_solr(solr_parameters, user_params)   

      # convert a String value into an Array
      if solr_parameters[:fq].is_a? String
        solr_parameters[:fq] = [solr_parameters[:fq]]
      end

      # :fq, map from :f. 
      if ( user_params[:f])
        f_request_params = user_params[:f] 
        
        solr_parameters[:fq] ||= []

        facet_list = f_request_params.keys.collect { |ff| ff.gsub(/^-/,'')}.uniq.sort


        facet_list.each do |facet_key|
          values = Array(f_request_params[facet_key])

          excluded_values = Array(f_request_params["-#{facet_key}"])
          operator = user_params[:f_operator] && user_params[:f_operator][facet_key] || "AND"
          solr_parameters[:fq] |= facet_value_to_fq_string(facet_key, values, excluded_values, operator)
        end
      end
    end

    def facet_value_to_fq_string(facet_field, values = [], excluded_values = [], operator ="AND")


      values = Array.wrap(values)
      excluded_values = Array.wrap(excluded_values)

      results = []
      values.each do |value|
        results << individual_facet_value_to_fq_string(facet_field, value, operator)
      end

      excluded_values.each do |value|
        results << individual_facet_value_to_fq_string("-#{facet_field}", value, operator)
      end

      results = ["(#{results.join(" OR ")})"] if operator == "OR"

      results
    end


    def individual_facet_value_to_fq_string(facet_field, value, operator ="AND")
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag


      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?


      fq = case
        when facet_field  =~ /^-/ || operator == "OR"
          "#{facet_field}:#{value}"
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
        else
          "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
      end
    end



    

end
