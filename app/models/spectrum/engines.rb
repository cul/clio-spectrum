module Spectrum
  module Engines
    def self.create(engine_name, engine_params = {} )
      "Spectrum::Engines::#{engine_name}".constantize.new(engine_params)
    end
  end
end
