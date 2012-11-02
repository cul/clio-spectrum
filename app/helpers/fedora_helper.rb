module FedoraHelper
  def fedora_method_url(doc, method)
    "#{APP_CONFIG['fedora']['riurl']}/objects/#{doc['id'].listify.first}/methods#{method}"
  end
end

