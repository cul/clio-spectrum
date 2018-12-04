require 'spec_helper'

describe ItemAlertsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/item_alerts')).to route_to('item_alerts#index')
    end

    it 'routes to #new' do
      expect(get('/item_alerts/new')).to route_to('item_alerts#new')
    end

    it 'routes to #show' do
      expect(get('/item_alerts/1')).to route_to('item_alerts#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get('/item_alerts/1/edit')).to route_to('item_alerts#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post('/item_alerts')).to route_to('item_alerts#create')
    end

    it 'routes to #update' do
      expect(put('/item_alerts/1')).to route_to('item_alerts#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete('/item_alerts/1')).to route_to('item_alerts#destroy', id: '1')
    end
  end
end
