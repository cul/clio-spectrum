
# NEXT-1103 - Catalog facet sorting is not working properly
puts "REMEMBER:  Remove facets_override.rb after upgrading Blacklight gem to 5.7.x"

module Blacklight::SolrResponse::Facets

  class FacetField
    attr_reader :name, :items

    def initialize name, items, options = {}
      @name, @items = name, items
      @options = options
    end

    def limit
      @options[:limit] || solr_default_limit
    end

    def sort
      @options[:sort] || solr_default_sort
    end

    def offset
      @options[:offset] || solr_default_offset
    end


    private

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
    def solr_default_limit
      100
    end

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.sort
    def solr_default_sort
      if limit > 0
        'count'
      else
        'index'
      end
    end

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.offset
    def solr_default_offset
      0
    end

  end
end
