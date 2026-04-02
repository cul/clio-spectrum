require 'spec_helper'

describe LocationsController do
  let(:locations) { Location.all }
  # let(:current_location) { Location.find_by_location_code("avery") }

  before do
    controller.instance_variable_set(:@locations, Location.all)
    controller.instance_variable_set(:@location, Location.find_by_location_code('avery'))
  end

  context "\nYou may need to run 'rake hours:update_all RAILS_ENV=test' and 'rake locations:load RAILS_ENV=test'.  See README.\n" do
    describe 'build_markers ' do

      it 'should query the Library API', focus: false do
        api_query = controller.library_api_path
        expect(RestClient).to receive(:get).with(api_query).and_call_original
        controller.build_markers
      end

      it 'should not have a marker for location that does not have a map' do
        markers = controller.build_markers
        expect(markers).not_to match(/chrdr/)
      end

      it 'should return json for each location with a location id' do
        markers = controller.build_markers
        cliolocs = Location.all.select { |loc| loc['location_code'] }.map { |loc| loc['location_code'] }.uniq
        cliolocs.each do |loc|
          # puts "loc=[#{loc}] markers=[#{markers}]"
          expect(markers).to match(loc)
        end
      end
    end

    describe 'library_api_path' do
      it 'returns the production path when config variable is missing' do
        allow(APP_CONFIG).to receive(:has_key?).with('library_api_path').and_return(false)
        path = controller.library_api_path
        expect(path).to eq('https://api.library.columbia.edu/locations/v2/query.json')
      end
    end
  end
end
