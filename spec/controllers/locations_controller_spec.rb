require 'spec_helper'

describe LocationsController do
  let(:locations) { Location.all }
  # let(:current_location) { Location.find_by_location_code("avery") }

  before do
    controller.instance_variable_set(:@locations, Location.all)
    controller.instance_variable_set(:@location, Location.find_by_location_code('avery'))
  end

  context "\nYou may need to run 'rake hours:sync RAILS_ENV=test' and 'rake locations:load RAILS_ENV=test'.  See README.\n" do
    describe 'build_markers ' do
      it 'should query the Library API', focus: false do
        api_query = controller.library_api_path, { params: { qt: 'location', locationID: 'alllocations' } }
        expect(RestClient).to receive(:get).with(api_query[0], api_query[1]).and_call_original
        controller.build_markers
      end

      # Bogus test - there's no guarantee of the order of locations in the array of location-markers
      # it 'assigns current marker' do
      #   controller.build_markers
      #   # What's the numeric position of "avery" in an
      #   # alphabetical list of markers?
      #   # expect(assigns(:current_marker_index)).to eq(0)
      #   # Now that "art-properties" has been added,
      #   # "avery" is bumped to array index position 1
      #   expect(assigns(:current_marker_index)).to eq(1)
      # end

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
        expect(path).to eq('https://api.library.columbia.edu/query.json')
      end
    end
  end
end
