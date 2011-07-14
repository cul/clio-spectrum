begin
  raw_config = File.read(RAILS_ROOT + "/config/app_config.yml")
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[RAILS_ENV] || {}
  APP_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
rescue
  APP_CONFIG = {}
end