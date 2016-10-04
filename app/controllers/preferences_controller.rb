class PreferencesController < ApplicationController
  layout 'quicksearch'

  before_filter :authenticate_user!, except: [:get_summon_facet_preferences]

  # before_action :set_preference, only: [:edit, :update, :destroy]
  before_action :set_preference

  
  # GET /preferences
  def index
    @preference = Preference.find_by(login: current_user.login )
  end
  
  # There's only ever a single preference for each user,
  # we'll display that on the index page, no 'show' needed.
  # # GET /preferences/1
  # def show
  # end
  
  # GET /preferences/new
  def new
    @preference = Preference.new
  end
  
  # GET /preferences/1/edit
  def edit
  end

  # POST /preferences
  def create
    @preference = Preference.new(preference_params)
  
    if @preference.save
      # redirect_to @preference, notice: 'Preferences set.'
      redirect_to preferences_url, notice: 'Preferences set.'
    else
      render :new
    end
  end
  
  # PATCH/PUT /preferences/1
  def update
    if @preference.update(preference_params)
      # redirect_to @preference, notice: 'Preferences updated.'
      redirect_to preferences_url, notice: 'Preferences updated.'
    else
      render :edit
    end
  end
  
  # DELETE /preferences/1
  def destroy
    @preference.destroy
    redirect_to preferences_url, notice: 'Preferences cleared.'
  end
  
  # Parameters look like: 
  # { "left"=>["geo=2", "library_web=2"], 
  #   "right"=>["dlc=1", "articles=1"] }
  # Map this to search_layout YAML
  def bentos
    @preference.update(preference_params)
    render nothing: true and return
  end





  private

    # Use callbacks to share common setup or constraints between actions.
    def set_preference
      return nil unless current_user
      
      @preference = Preference.find_by(login: current_user.login )
      # @settings = YAML.parse(@preference['settings']) || {}
      
      # make available throughout view forms
      
      # - for bentos
      @all_bentos = BENTO_DATASOURCES
      @system_quicksearch_layout = get_system_search_layout('quicksearch')
      @user_quicksearch_layout = get_user_search_layout('quicksearch') || @system_quicksearch_layout
      
      # - for summon
      @all_summon_facets = Spectrum::SearchEngines::Summon::AVAILABLE_SUMMON_FACETS
      @system_summon_facets = get_system_summon_facets
      @user_summon_facets = get_user_summon_facets || @system_summon_facets
    end



    # Only allow a trusted parameter "white list" through.
    def preference_params
      saved_preferences = Preference.find_by(login: current_user.login )
      settings_hash = YAML.load(saved_preferences['settings']) || {}

settings_hash.delete('search_layouts')
      # # cleanup accidental nils
      # settings_hash.each do |key, value|
      #   settings_hash.delete(key) if value.nil?
      # end

      if summon_facets = params_to_summon_facets(params)
        settings_hash['summon_facets'] = summon_facets
      end

      if datasource_sidebar = params_to_datasource_sidebar(params)
        settings_hash['datasource_sidebar'] = datasource_sidebar
      end

      # 'search_layouts' in config file,
      # effectively it's control over our quicksearch bento boxes
      if search_layouts = params_to_quicksearch_bentos(params)
        settings_hash[:search_layouts] = search_layouts
      end
# raise

      ActionController::Parameters.new.permit(:login, :settings).merge(login: current_user.login).merge(settings: settings_hash.to_yaml)
    end


    # arbitrary transformation rules
    # from form params to configuration hash

    def params_to_summon_facets(params)
      return nil unless params['summon_facets']
      summon_facets = params['summon_facets'].to_hash
      summon_facets.delete_if { |facet, value|
        value.blank? or value.to_i == 0
      }
    end

    def params_to_datasource_sidebar(params)
    end

    def params_to_quicksearch_bentos(params)
      return nil unless params['bento_left'] || params['bento_right']
      
      left = []
      Array(params['bento_left']).each do |param|
        source, count = param.split(/:/)
        next if count == 0
        left.push( {'source': source, 'count': count} )
      end
      
      right = []
      Array(params['bento_right']).each do |param|
        source, count = param.split(/:/)
        next if count == 0
        right.push( {'source': source, 'count': count} )
      end
      columns = [{ searches: left }, { searches: right }]
      quicksearch = { style: 'aggregate', columns: columns }
      return { quicksearch: quicksearch }
    end

end
