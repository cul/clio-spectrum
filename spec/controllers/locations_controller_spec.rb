require 'spec_helper'
require 'rake'

describe LocationsController do
  let(:locations){Location.all}
  let(:current_location) {Location.find_by_library_code("avery")}
  before do
    Location.clear_and_load_fixtures!
    Rake.application.rake_require 'tasks/solr_ingest'
    Rake.application.rake_require 'tasks/sync_hours'
    Rake::Task.define_task(:environment)
    Rake.application.invoke_task 'hours:sync'
  end
  describe "build_markers" do
    it "should query the Library API" do
      api_query = "http://api.library.columbia.edu/query.json", {:params=>{:qt=>"location", :locationID=>"alllocations"}}
      expect(RestClient).to receive(:get).with(api_query[0], api_query[1]).and_call_original
      controller.build_markers
    end

    it "assigns current marker" do
      controller.instance_variable_set(:@locations, Location.all)
      controller.instance_variable_set(:@location, Location.find_by_library_code("avery"))
      controller.build_markers
      expect(assigns(:current_marker_index)).to eq(0)
    end

    it "has different location codes for butler-24 and barnard-archives" do
      pending
    end

    it 'should display the infowindow for the current marker' do
      pending
    end

    it "should return json for each location with a location id" do
      markers = controller.build_markers
      cliolocs = Location.all.map{|loc| loc.library_code}.uniq
      liblocs = @library_api_info.map{|loc| loc['locationID'] }
      liblocs.each do loc
        expect(markers).to match(/loc/)
      end
    end
  end
end
