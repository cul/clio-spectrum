begin
  # No interpolation
  # raw_config = File.read(Rails.root.to_s + '/config/app_config.yml')
  # loaded_config = YAML.load(raw_config)
  # Interpolation
  app_config_file = Rails.root.to_s + '/config/app_config.yml'
  loaded_config = YAML.load(ERB.new(IO.read(app_config_file)).result) || {}

  all_config = loaded_config['_all_environments'] || {}
  env_config = loaded_config[Rails.env] || {}
  APP_CONFIG ||= all_config.merge(env_config)
rescue
  APP_CONFIG = {}
end

PERMISSIONS_CONFIG ||= YAML.load(File.read(Rails.root.to_s + '/config/permissions.yml'))
DATASOURCES_CONFIG ||= YAML.load(File.read(Rails.root.to_s + '/config/datasources.yml'))
SEARCHES_CONFIG ||= YAML.load(File.read(Rails.root.to_s + '/config/searches.yml'))
raw_config = File.read(Rails.root.to_s + '/config/marc_display_fields.yml')
marc_config = YAML.load(raw_config)
MARC_FIELDS ||= marc_config

# No interpolation
# SOLR_CONFIG ||= YAML.load(File.read(Rails.root.to_s + '/config/blacklight.yml'))
# Interpolation
blacklight_config_file = Rails.root.to_s + '/config/blacklight.yml'
SOLR_CONFIG ||= YAML.load(ERB.new(IO.read(blacklight_config_file)).result) || {}


DONOR_INFO ||= YAML.load(File.read(Rails.root.to_s + '/config/donor_info.yml'))
ITEM_STATUS_CODES ||= YAML.load(File.read(Rails.root.to_s + '/config/item_status_codes.yml'))
ORDER_STATUS_CODES ||= YAML.load(File.read(Rails.root.to_s + '/config/order_status_codes.yml'))

OFFSITE_CONFIG ||= YAML.load(File.read(Rails.root.to_s + '/config/offsite.yml'))


