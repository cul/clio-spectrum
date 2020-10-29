module Spectrum
  module Queries
    class Solr
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      include AdvancedHelper
      include LocalSolrHelperExtension

      include Blacklight::FacetsHelperBehavior
      # for "add_facet_params"
      include Blacklight::UrlHelperBehavior

      attr_reader :params, :queries, :filters, :ranges, :query_operator

      def initialize(reg_params, blacklight_config)
        @params = reg_params.to_unsafe_h || HashWithIndifferentAccess.new
        
        @params = strip_foia_negation if APP_CONFIG['foia_exclusion']
        
        @config = blacklight_config
        # raise
        parse_queries
        parse_filters
        parse_ranges
      end

      def blacklight_config
        @config
      end

      def has_constraints?
        !(@filters.empty? && @queries.empty? && @ranges.empty?)
      end

      def query_operator_label
        @query_operator == 'AND' ? 'All Of' : 'Any Of'
      end

      def query_operator_change_links
        if @query_operator == 'AND'
          [
            ['All Of', '#'],
            ['Any Of', catalog_index_path(change_params_and_redirect({ advanced_operator: 'OR' }, @params))]
          ]
        else
          [
            ['All Of', catalog_index_path(change_params_and_redirect({ advanced_operator: 'AND' }, @params))],
            ['Any Of', '#']
          ]
        end
      end

      def multiple_queries?
        @queries.length > 1
      end

      private

      def is_inverted?(facet_field)
        facet_field =~ /^-/
      end

      def inverted_facet_field(facet_field)
        is_inverted?(facet_field) ? facet_field.gsub(/^-/, '') : "-#{facet_field}"
      end

      # Create new params for the inversion of facet_field=value
      # For:
      #   @params = {"f"=>{"format"=>["Book", "Online"]}, ...etc... }
      #   facet_field = format
      #   value = Book
      # Return:
      #   @params = {"f"=>{"-format"=>["Book"], "format"=>["Online"]}, ...etc... }
      #
      def invert_facet_value(facet_field, value)
        # # start with our current params...
        # new_params = @params.deep_clone
        #
        # # remove what we don't want...
        # new_params.delete(:page)
        # new_params.delete(:id)
        # Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key|
        #   new_params.delete(paginator_key)
        # end
        # # send them to the index (search results)
        # new_params[:action] = 'index'
        #
        # # Remove
        #
        # deprecated
        # new_params = remove_facet_params(facet_field, value, new_params)
        search_state = Blacklight::SearchState.new(@params, blacklight_config)
        new_params = search_state.remove_facet_params(facet_field, value)

        search_state = Blacklight::SearchState.new(new_params.to_h, blacklight_config)
        new_params = search_state.add_facet_params(inverted_facet_field(facet_field), value)

        # # deprecated
        # # new_params = add_facet_params(inverted_facet_field(facet_field), value, new_params)
        # new_params = Blacklight::SearchState.new(new_params, blacklight_config).
        #              add_facet_params(inverted_facet_field(facet_field), value)
        new_params
      end

      # Each invert_link is an array of [label, link]
      def facet_value_invert_links(facet_field, value)
        if is_inverted?(facet_field)
          [
            ['Is Not', '#'],
            ['Is', catalog_index_path(invert_facet_value(facet_field, value))]
          ]
        else
          [
            ['Is', '#'],
            ['Is Not', catalog_index_path(invert_facet_value(facet_field, value))]
          ]
        end
      end

      def facet_operator_change_links(raw_facet_field)
        if facet_operator(raw_facet_field) == 'AND'
          new_facet_operators = (@params[:f_operator] || {}).dup
          new_facet_operators[raw_facet_field] = 'OR'
          [
            ['All Of', '#'],
            ['Any Of', catalog_index_path(change_params_and_redirect({ f_operator: new_facet_operators }, @params))]
          ]
        else
          new_facet_operators = (@params[:f_operator] || {}).dup
          new_facet_operators[raw_facet_field] = 'AND'
          [
            ['All Of', catalog_index_path(change_params_and_redirect({ f_operator: new_facet_operators }, @params))],
            ['Any Of', '#']
          ]

        end
      end

      def facet_operator(raw_facet_field)
        (@params[:f_operator] && @params[:f_operator][raw_facet_field]) || 'AND'
      end

      def facet_operator_label(raw_facet_field)
        facet_operator(raw_facet_field) == 'AND' ? 'All Of' : 'Any Of'
      end

      def facet_label(facet_field, base_facet_field)
        @config.facet_fields[base_facet_field.to_s] &&
          @config.facet_fields[base_facet_field.to_s].label ||
          facet_field
      end

      def parse_filters
        @filters = HashWithIndifferentAccess.new
        (@params[:f] || {}).each_pair do |facet_field, values|
          # values has to be an array, and cannot be empty, or don't process this filter
          next unless values.is_a? Array
          next if values.nil? || (!values.is_a? Array) || values.join.empty?

          base_facet_field = facet_field.gsub(/^-/, '').to_s

          unless @filters.key?(base_facet_field)
            @filters[base_facet_field] = {
              operator: facet_operator(base_facet_field),
              operator_label: facet_operator_label(base_facet_field),
              operator_change_links: facet_operator_change_links(base_facet_field),
              values: [],
              # label: @config.facet_fields[base_facet_field.to_s].label || facet_field
              label: facet_label(facet_field, base_facet_field)
            }
          end

          values.each do |value|
            display_value = value
            # Sometimes the value is something like "week_1", that needs
            # to be mapped back into a displayable label.  Look into the
            # facet field configuration to do this if we need to.
            if fq_config = @config.facet_fields[base_facet_field.to_s]
              if fq_config[:query] &&
                 fq_config[:query][value] &&
                 fq_config[:query][value][:label]
                display_value = fq_config[:query][value][:label]
              end
            end
            # raise
            # # deprecated
            # # new_params = remove_facet_params(facet_field, value, new_params)
            # search_state = Blacklight::SearchState.new(@params, blacklight_config)
            # new_params = search_state.remove_facet_params(facet_field, value)
            #
            # search_state.remove_facet_params(facet_field, value)
            # ... trying to cleanup deprecation ...
            search_state = Blacklight::SearchState.new(@params, blacklight_config)
            @filters[base_facet_field][:values] << {
              invert_label: is_inverted?(facet_field) ? 'Is Not' : 'Is',
              label: display_value,
              remove: search_state.remove_facet_params(facet_field, value),
              # Each invert_link is an array of [label, link]
              invert_links: facet_value_invert_links(facet_field, value)
            }
          end
        end
      end

      def parse_queries
        @queries = []

        if @params[:search_field] == 'advanced'
          (@params['adv'] || {}).each_pair do |i, attrs|
            field = attrs['field']
            value = attrs['value']
            next if value.to_s.empty?
            remove_params = @params.deep_clone
            # remove_params[:action] = 'index'
            # "Calling URL helpers with string keys controller, action is deprecated"
            remove_params.delete(:controller)
            remove_params.delete(:action)
            # let controller / action be handled by rails

            remove_params[:adv][i] = nil
            remove_params.delete(:page)
            remove_params.delete(:id)

            @queries << {
              field: field,
              value: value,
              remove: catalog_index_path(remove_params)
            }
          end
        else
          unless @params[:q].to_s.empty?
            remove_params = @params.deep_clone
            # remove_params[:action] = 'index'
            # "Calling URL helpers with string keys controller, action is deprecated"
            remove_params.delete(:controller)
            remove_params.delete(:action)
            # let controller / action be handled by rails
            remove_params[:q] = nil
            remove_params.delete(:page)
            remove_params.delete(:id)
            field = @params[:search_field] || 'all_fields'
            @queries = [{ field: field, value: @params[:q], remove: catalog_index_path(remove_params) }]
          end
        end

        @queries.each do |query|
          field_key = query[:field]
          query[:label] = if search_field = @config.search_fields[field_key]
                            search_field.label
                          else
                            field_key
                          end
        end

        @query_operator = @params[:advanced_operator] || 'AND'
      end

      def parse_ranges
        @ranges = HashWithIndifferentAccess.new

        (@params[:range] || {}).each_pair do |range_key, range|
          # defend against bad input
          next unless range_key && range && @config.facet_fields[range_key]
          @ranges[range_key] = {
            label: @config.facet_fields[range_key].label || range_key,
            value: "#{range['begin']} to #{range['end']}",
            remove: remove_range_params(range_key, @params)
          }
        end
      end


      # NEXT-1645 - Committee-driven software development!
      # This method called above in initialize() like this:
      #   @params = strip_foia_negation if APP_CONFIG['foia_exclusion']
      # Depending on the query, @params may look like:
      #   {"f"=>{"-format"=>["FOIA Document"]}, "q"=>"test"}
      #   {"f"=>{"-format"=>["FOIA Document"], "format"=>["Book"]}, "q"=>"test"}
      #   {"f"=>{"-format"=>["FOIA Document", "Book"]}, "q"=>"test"}
      #   {"f"=>{"-format"=>["FOIA Document", "Book"]}, "f_operator"=>{"format"=>"OR"}, "q"=>"test"}
      def strip_foia_negation
        return @params unless @params && @params[:f] && @params[:f]['-format']
        
        # Delete the "FOIA Document" format negation, if found
        @params[:f]['-format'].delete('FOIA Document')
        
        # Delete the format-negation key, if "FOIA Document" was the only format-negation
        @params[:f].delete('-format') if @params[:f]['-format'].empty?
        
        # Delete the facet/filter key, if format-negation was the only facet/filter
        @params.delete(:f) if @params[:f].empty?
        
        # Return whatever @params looks like now
        @params
      end

    end
  end
end
