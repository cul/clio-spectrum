
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder


  self.default_processor_chain += [:add_advanced_search_to_solr]
  # self.default_processor_chain += [:add_range_limit_params]
  self.default_processor_chain += [:add_debug_to_solr]
  self.default_processor_chain += [:trim_long_queries]

  # These methods are passed a hash, which will
  # become the Solr request parameters.
  # Their job is to fill this hash with keys/values, based
  # on another hash - blacklight_params - which is available
  # to subclasses of Blacklight::Solr::SearchBuilder

  # NEXT-1043 - Better handling of extremely long queries
  def trim_long_queries(solr_parameters)

    # If there's no 'q', don't do anything
    return unless solr_parameters['q']

    # For shelf-browse we construct monstrous queries against the shelfkey field
    return if solr_parameters['q'].include? "shelfkey:"

    # Truncate queries longer than N letters
    maxLetters = 200
    if solr_parameters['q'].size > maxLetters
      # flash.now[:error] = "Your query was automatically truncated to the first #{maxLetters} letters. Letters beyond this do not help to further narrow the result set."
      solr_parameters['q'] = solr_parameters['q'].first(maxLetters)
    end

    # Truncate queries longer than N words
    maxTerms = 30
    terms = solr_parameters['q'].split(' ')
    if terms.size > maxTerms
      # flash.now[:error] = "Your query was automatically truncated to the first #{maxTerms} words.  Terms beyond this do not help to further narrow the result set."
      solr_parameters['q'] = terms[0,maxTerms].join(' ')
    end

  end

  def add_debug_to_solr(solr_parameters)
    solr_parameters[:debugQuery] = :true if  blacklight_params[:debugQuery] == "true"
  end


  def add_advanced_search_to_solr(solr_parameters)
    # Only continue if the blacklight params indicate this is 
    # an advanced search
    return unless blacklight_params[:search_field] == 'advanced' && blacklight_params[:adv].kind_of?(Hash)

    solr_parameters[:qt] = blacklight_params[:qt] if blacklight_params[:qt]

    # NEXT-922 - Advanced search item pagination skips records from search-results list
    # fix: skip over empty advanced-search fields (don't AND empty strings)
    advanced_q = advanced_search_queries(blacklight_params).reject do |query|
      field_name, value = *query
      !value || (value.strip.length == 0)
    end.map do |query|
      field_name, value = *query
      search_field_def = blacklight_config.search_fields[field_name]

      # The search_field_def may look something like this:
      # <Blacklight::Configuration::SearchField 
      #    key="journal_title", 
      #    show_in_dropdown=true,
      #    solr_parameters={:fq=>["format:Journal\\/Periodical"]},
      #    solr_local_parameters={:qf=>"$title_qf", :pf=>"$title_pf"},
      #    if=true, 
      #    field="journal_title", 
      #    label="Journal Title",
      #    unless=false, 
      #    qt="search">

      # ==> process the solr_local_parameters
      # does searching by this field oblige us to merge
      # in some specific solr parameters?  
      # (e.g., a "Journal Title" search means fq:'format:Journal')
      if search_field_def && search_field_def.solr_parameters
        search_field_def.solr_parameters.map do |key, value|
          solr_parameters[key] ||= []
          solr_parameters[key] |= value
        end
        # solr_parameters.merge!(search_field_def.solr_parameters)
      end

      # ==> process the solr_local_parameters
      if search_field_def && hash = search_field_def.solr_local_parameters
        local_params = hash.map do |key, val|
          key.to_s + '=' + solr_param_quote(val, quote: "'")
        end.join(' ')

        # This has problems. Why "_query_"?  Why dismax?
        # No comments, no explanation.

        # "_query_:\"{!dismax #{local_params}}#{value}\""
        # if they submitted a quoted value, escape their quotes for them
        "_query_:\"{!dismax #{local_params}}#{value.gsub(/"/, '\"')}\""

        # # testing....
        # "{!#{local_params}}#{value.gsub(/"/, '\"')}"

      else
        value.to_s
      end

      # TODO:  process the solr_parameters (e.g., :fq)

    end
    Rails.logger.debug "FINAL: #{advanced_q}"

    solr_parameters[:q] = advanced_q.join(" #{advanced_search_operator(blacklight_params)} ")
  end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # as :f, to solr as appropriate :fq query.
  # Local CLIO override of Blacklight method, 
  # to support negative (excluded) facets
  def add_facet_fq_to_solr(solr_parameters)
    user_params = blacklight_params
    # convert a String value into an Array
    if solr_parameters[:fq].is_a? String
      solr_parameters[:fq] = [solr_parameters[:fq]]
    end

    # :fq, map from :f.
    if  user_params[:f]
      f_request_params = user_params[:f]

      solr_parameters[:fq] ||= []

      facet_list = f_request_params.keys.map { |ff| ff.gsub(/^-/, '') }.uniq.sort

      facet_list.each do |facet_key|
        values = Array(f_request_params[facet_key]).reject(&:empty?)

        excluded_values = Array(f_request_params["-#{facet_key}"])
        operator = user_params[:f_operator] && user_params[:f_operator][facet_key] || 'AND'
        solr_parameters[:fq] |= facet_value_to_fq_string(facet_key, values, excluded_values, operator)
      end
    end
  end


  # # fetch proper things for date ranges.
  # def add_range_limit_params(solr_params)
  #   ranged_facet_configs =
  #     blacklight_config.facet_fields.select { |key, config| config.range }
  #    # In ruby 1.8, hash.select returns an array of pairs, in ruby 1.9
  #    # it returns a hash. Turn it into a hash either way.
  #   ranged_facet_configs = Hash[ ranged_facet_configs] unless ranged_facet_configs.kind_of?(Hash)
  # 
  #   ranged_facet_configs.each_pair do |solr_field, config|
  #    solr_params['stats'] = 'true'
  #    solr_params['stats.field'] ||= []
  #    solr_params['stats.field'] << solr_field unless
  #        solr_params['stats.field'].include?(solr_field)
  # 
  #    hash = blacklight_params[:range] && blacklight_params[:range][solr_field] ?
  #              blacklight_params[:range][solr_field] :
  #              {}
  # 
  #    if !hash['missing'].blank?
  #      # missing specified in request params
  #      solr_params[:fq] ||= []
  #      solr_params[:fq] << "-#{solr_field}:[* TO *]"
  # 
  #    elsif !(hash['begin'].blank? && hash['end'].blank?)
  #      # specified in request params, begin and/or end, might just have one
  #      start = hash['begin'].blank? ? '*' : hash['begin']
  #      finish = hash['end'].blank? ? '*' : hash['end']
  #      fq_value = "#{solr_field}: [#{start} TO #{finish}]"
  # 
  #      solr_params[:fq] ||= []
  #      solr_params[:fq] << fq_value unless solr_params[:fq].include?(fq_value)
  # 
  #      if config.segments != false && start != '*' && finish != '*'
  #        # Add in our calculated segments, can only do with both boundaries.
  #        add_range_segments_to_solr!(solr_params, solr_field, start.to_i, finish.to_i)
  #      end
  # 
  #    elsif config.segments != false &&
  #           boundaries = config.assumed_boundaries
  #      # assumed_boundaries in config
  #      add_range_segments_to_solr!(solr_params, solr_field, boundaries[0], boundaries[1])
  #    end
  #  end
  # 
  #   solr_params
  # end

  private

  def advanced_search_operator(req_params = params)
    advanced_operator = req_params[:advanced_operator] || 'AND'
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

  def facet_value_to_fq_string(facet_field, values = [], excluded_values = [], operator = 'AND')
    values = Array.wrap(values)
    excluded_values = Array.wrap(excluded_values)

    results = []
    values.each do |value|
      results << individual_facet_value_to_fq_string(facet_field, value, operator)
    end

    excluded_values.each do |value|
      results << individual_facet_value_to_fq_string("-#{facet_field}", value, operator)
    end

    results = ["(#{results.join(" OR ")})"] if operator == 'OR'

    results
  end

  def individual_facet_value_to_fq_string(facet_field, value, operator = 'AND')
    # For mapped facets (e.g., "week_1"), we need to dig up the facet config
    # to decode back to an actual value (e.g., [2015-01-14T00:00:00Z TO *])
    # [n.b., the facet-field may be negated with a hyphen, so account for that]
    facet_config = blacklight_config.facet_fields[facet_field.sub(/^-/, '')]

    local_params = []
    local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

    prefix = ''
    prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?

    double_slash = '\\\\'
    escaped_quote = '\"'

    subbed_value = '"' + value.gsub('\\', double_slash).gsub('"', escaped_quote) + '"'

    fq = case
      # If we somehow got here with an empty value, do not create a Solr fq clause
      when value == ''
        ''
      # This line maps symbolic facet values (e.g., "week_1") to
      # true values (e.g., acq_dt:[2015-01-14T00:00:00Z TO *])
      when (facet_config and facet_config.query and facet_config.query[value])
        negator = (facet_field  =~ /^-/) ? '-' : ''
        negator + facet_config.query[value][:fq]
      # Handle simple inverted facet fields
      when facet_field  =~ /^-/ || operator == 'OR'
        "#{facet_field}:#{subbed_value}"
      when (facet_config and facet_config.date),
           (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
           (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
           (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
           (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
           "#{prefix}#{facet_field}:#{value}"
      when value.is_a?(Range)
        "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
      else
        # NEXT-1107 -Pre-composed characters in facets
        # Remove "raw" to allow analyzer to normalize unicode
        # "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
        # "#{facet_field}:\"#{value}\""
        # We need the version with internal quotes/backslashes escaped
        "#{facet_field}:#{subbed_value}"
    end
  end


end

