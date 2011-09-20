module GenericFacetsHelper
  def facet_paginator(facet)
    Blacklight::Solr::FacetPaginator.new(facet[:items], :limit => facet[:limit])
  end


end
