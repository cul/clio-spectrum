module Spectrum
  module Queries
    class Solr
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      include AdvancedHelper
      include LocalSolrHelperExtension
      include Blacklight::FacetsHelperBehavior

      attr_reader :params, :queries, :filters, :ranges, :query_operator

      def initialize(reg_params, blacklight_config)
        @params = reg_params || HashWithIndifferentAccess.new()
        @config = blacklight_config
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
        @query_operator == "AND" ? "All Of" : "Any Of"
      end

      def query_operator_change_links
        if @query_operator == "AND"
          [
            ["All Of", "#"],
            ["Any Of", catalog_index_path(change_params_and_redirect({:advanced_operator => 'OR'}, @params))]
          ]
        else
          [
            ["All Of", catalog_index_path(change_params_and_redirect({:advanced_operator => 'AND'}, @params))],
            ["Any Of", "#"]
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
        is_inverted?(facet_field) ? facet_field.gsub(/^-/, "") : "-#{facet_field}"
      end

      def invert_facet_value(facet_field, value)
        new_params = @params.deep_clone
        new_params.delete(:page)

        Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key|
          new_params.delete(paginator_key)
        end

        new_params.delete(:id)

        new_params[:action] = "index"
        new_params = remove_facet_params(facet_field, value, new_params)
        new_params = add_facet_params(inverted_facet_field(facet_field), value, new_params)
        new_params

      end

      def facet_value_invert_links(facet_field,value)

        if  is_inverted?(facet_field)
          [
            ["Is Not", "#"],
            ["Is", catalog_index_path(invert_facet_value(facet_field, value))]
          ]
        else
          [
            ["Is", "#"],
            ["Is Not", catalog_index_path(invert_facet_value(facet_field, value))]
          ]
        end
      end

      def facet_operator_change_links(raw_facet_field)
        if facet_operator(raw_facet_field) == "AND"
          new_facet_operators = (@params[:f_operator] || {}).dup
          new_facet_operators[raw_facet_field] = 'OR'
          [
            ["All Of", "#"],
            ["Any Of", catalog_index_path(change_params_and_redirect({:f_operator => new_facet_operators}, @params))]
          ]
        else
          new_facet_operators = (@params[:f_operator] || {}).dup
          new_facet_operators[raw_facet_field] = 'AND'
          [
            ["All Of", catalog_index_path(change_params_and_redirect({:f_operator => new_facet_operators}, @params))],
            ["Any Of", "#"]
          ]

        end
      end

      def facet_operator(raw_facet_field)
        (@params[:f_operator] && @params[:f_operator][raw_facet_field]) || "AND"
      end

      def facet_operator_label(raw_facet_field)
        facet_operator(raw_facet_field) == "AND" ? "All Of" : "Any Of"
      end

      def parse_filters
        @filters = HashWithIndifferentAccess.new()
        (@params[:f] || {}).each_pair do |facet_field, values|
          base_facet_field = facet_field.gsub(/^-/,'').to_s

          unless @filters.has_key?(base_facet_field)
            @filters[base_facet_field] = {
              operator: facet_operator(base_facet_field),
              operator_label: facet_operator_label(base_facet_field),
              operator_change_links: facet_operator_change_links(base_facet_field),
              values: [],
              label: @config.facet_fields[base_facet_field.to_s].label || facet_field

            }

          end


          values.each do |value|
            @filters[base_facet_field][:values] << {
              invert_label: is_inverted?(facet_field) ? "Is Not" : "Is",
              label: value,
              remove: remove_facet_params(facet_field, value, @params),
              invert_links: facet_value_invert_links(facet_field, value)

            }
          end
        end
      end

      def parse_queries
        @queries = []

        if @params[:search_field] == "advanced"
          (@params['adv'] || {}).each_pair  do |i, attrs|
            field, value = attrs['field'], attrs['value']
            unless value.to_s.empty?
              remove_params = @params.deep_clone
              remove_params[:action] = 'index'
              remove_params[:adv][i] = nil
              remove_params.delete(:page)
              remove_params.delete(:id)

              @queries << {
                :field => field,
                :value => value,
                :remove => catalog_index_path(remove_params)
              }


            end

          end
        else
          unless @params[:q].to_s.empty?
            remove_params = @params.deep_clone
            remove_params[:action] = 'index'
            remove_params[:q] = nil
            remove_params.delete(:page)
            remove_params.delete(:id)
            field = @params[:search_field] || "all_fields"
            @queries = [{:field => field, :value => @params[:q], :remove => catalog_index_path(remove_params)}]
          end
        end

        @queries.each do |query|
          field_key = query[:field]
          if search_field = @config.search_fields[field_key]
            query[:label] = search_field.label
          else
            query[:label] = field_key
          end
        end

        @query_operator = @params[:advanced_operator] || "AND"
      end

      def parse_ranges
        @ranges = HashWithIndifferentAccess.new()

        (@params[:range] || {}).each_pair do |range_key, range|
          @ranges[range_key] = {

              label: @config.facet_fields[range_key].label || range_key,
              value: "#{range['begin']} to #{range['end']}",
              remove: remove_range_params(range_key, @params)

            }



        end

      end

    end
  end
end
