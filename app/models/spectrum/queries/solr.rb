module Spectrum
  module Queries
    class Solr
      include Rails.application.routes.url_helpers
      Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
      include AdvancedHelper
      include LocalSolrHelperExtension

      attr_reader :params, :queries, :filters, :query_operator

      def initialize(reg_params, blacklight_config)
        @params = reg_params || HashWithIndifferentAccess.new()
        @config = blacklight_config
        parse_queries
        parse_filters

      
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

      def parse_filters
        @filters = HashWithIndifferentAccess.new()
      end

      def parse_queries
        @queries = HashWithIndifferentAccess.new()
        
        if @params[:search_field] == "advanced"
          (@params[:advanced] || {}).each do |field, value|
            unless value.to_s.empty?
              remove_params = @params.deep_clone
              remove_params[:action] = 'index'
              remove_params[:advanced][field] = nil
              remove_params.delete(:page)
              remove_params.delete(:id)

              @queries[field.to_s] = {
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
            @queries[field] = {:value => @params[:q], :remove => catalog_index_path(remove_params)}
          end
        end
      
        @queries.keys.each do |field_key|
          if search_field = @config.search_fields[field_key]
            @queries[field_key][:label] = search_field.label
          else
            @queries[field_key][:label] = field_key
          end
        end
        
        @query_operator = @params[:advanced_operator] || "AND"
      end

    end
  end
end
