module LocalSolrHelperExtension
  extend ActiveSupport::Concern
  include Blacklight::SolrHelper
  include BlacklightRangeLimit::SegmentCalculation

  def is_advanced_search?(req_params = params)
    req_params[:search_field] == 'advanced' && req_params[:adv].kind_of?(Hash)

  end

  def advanced_search_operator(req_params = params)
    advanced_operator = req_params[:advanced_operator] || "AND"
  end

  def advanced_search_queries(req_params = params)
    if req_params[:adv].kind_of?(Hash)
      advanced_queries = []
      req_params[:adv].each_pair do |i, attrs|
        advanced_queries << [attrs['field'], attrs['value']]
      end
      advanced_queries
    else
      {}
    end
  end


    # Returns range config hash for named solr field. Returns false
    # if not configured. Returns hash even if configured to 'true'
    # for consistency.
    def range_config(solr_field)
      field = blacklight_config.facet_fields[solr_field]
      return false unless field.range

      config = field.range
      config = {} if config === true

      config
    end


    # Method added to solr_search_params_logic to fetch
    # proper things for date ranges.
    def add_range_limit_params(solr_params, req_params)
       ranged_facet_configs =
         blacklight_config.facet_fields.select { |key, config| config.range }
       # In ruby 1.8, hash.select returns an array of pairs, in ruby 1.9
       # it returns a hash. Turn it into a hash either way.
       ranged_facet_configs = Hash[ ranged_facet_configs ] unless ranged_facet_configs.kind_of?(Hash)

       ranged_facet_configs.each_pair do |solr_field, config|
        solr_params["stats"] = "true"
        solr_params["stats.field"] ||= []
        solr_params["stats.field"] << solr_field unless
            solr_params["stats.field"].include?(solr_field)

        hash = req_params[:range] && req_params[:range][solr_field] ?
                  req_params[:range][solr_field] :
                  {}

        if !hash["missing"].blank?
          # missing specified in request params
          solr_params[:fq] ||= []
          solr_params[:fq] << "-#{solr_field}:[* TO *]"

        elsif !(hash["begin"].blank? && hash["end"].blank?)
          # specified in request params, begin and/or end, might just have one
          start = hash["begin"].blank? ? "*" : hash["begin"]
          finish = hash["end"].blank? ? "*" : hash["end"]
          fq_value = "#{solr_field}: [#{start} TO #{finish}]"

          solr_params[:fq] ||= []
          solr_params[:fq] << fq_value unless solr_params[:fq].include?(fq_value)

          if (config.segments != false && start != "*" && finish != "*")
            # Add in our calculated segments, can only do with both boundaries.
            add_range_segments_to_solr!(solr_params, solr_field, start.to_i, finish.to_i)
          end

        elsif (config.segments != false &&
               boundaries = config.assumed_boundaries)
          # assumed_boundaries in config
          add_range_segments_to_solr!(solr_params, solr_field, boundaries[0], boundaries[1])
        end
      end

      return solr_params
    end



  def add_advanced_search_to_solr(solr_parameters, req_params = params)
    if is_advanced_search?(req_params)

      solr_parameters[:qt] = req_params[:qt] if req_params[:qt]

      # NEXT-922 - Advanced search item pagination skips records from search-results list
      # fix: skip over empty advanced-search fields (don't AND empty strings)
      advanced_q = advanced_search_queries(req_params).reject do |query|
        field_name, value = *query
        !value || (value.strip.length == 0)
      end.collect do |query|
        field_name, value = *query
        search_field_def = search_field_def_for_key(field_name)

        if (search_field_def && hash = search_field_def.solr_local_parameters)
          local_params = hash.collect do |key, val|
            key.to_s + "=" + solr_param_quote(val, :quote => "'")
          end.join(" ")

          # if they submitted a quoted value, escape their quotes for them
          "_query_:\"{!dismax #{local_params}}#{value.gsub(/"/, '\"')}\""

        else
          value.to_s
        end

      end
      Rails.logger.error "FINAL: #{advanced_q}"


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

  def remove_range_params(range_key, source_params=params)
    p = source_params.deep_clone
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:range] && p[:range].delete(range_key)
    p

  end

  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes additional params (page, id, etc..)
  def remove_facet_params(field, item, source_params=params)
    if item.respond_to? :field
      field = item.field
    end

    value = facet_value_for_facet_item(item)

    p = source_params.dup
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = (p[:f] || {}).dup
    p[:f][field] = (p[:f][field] || []).dup
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:f][field] = p[:f][field] - [value]
    p[:f].delete(field) if p[:f][field].size == 0
    p
  end



    def individual_facet_value_to_fq_string(facet_field, value, operator ="AND")
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag


      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

      double_slash = '\\\\'
      escaped_quote = '\"'

      subbed_value = '"' + value.gsub("\\", double_slash).gsub('"', escaped_quote) + '"'


      fq = case
        # If we somehow got here with an empty value, do not create a Solr fq clause
        when value == ''
          ""
        when facet_field  =~ /^-/ || operator == "OR"
          "#{facet_field}:#{subbed_value}"
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
