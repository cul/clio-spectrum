class BestBetsController < ApplicationController
  before_action :set_best_bet, only: [:show, :edit, :update, :destroy]

  def hits
    q = params['q']

    # if ActiveRecord::Base.connection.adapter_name.match /sqlite/i
    #   wildcard = '%' + q.gsub(/ +/, '%') + '%'
    #   @hits = BestBet.where('title || url || description || keywords LIKE ?', wildcard)
    # end
    # 
    # if ActiveRecord::Base.connection.adapter_name.match /mysql/i
    #   @hits = BestBet.where('match(title,url,description,keywords) against (?)', q)
    # end

    wildcard = q.strip.gsub(/ +/, '% ') + '%'
    @hits = BestBet.where('title || url || description || keywords LIKE ?', wildcard)

  end

  # GET /best_bets
  # GET /best_bets.json
  def index
    @best_bets = BestBet.all
  end

  # GET /best_bets/1
  # GET /best_bets/1.json
  def show
  end

  # GET /best_bets/new
  def new
    @best_bet = BestBet.new
  end

  # GET /best_bets/1/edit
  def edit
  end

  # POST /best_bets
  # POST /best_bets.json
  def create
    @best_bet = BestBet.new(best_bet_params)

    respond_to do |format|
      if @best_bet.save
        format.html { redirect_to @best_bet, notice: 'Best bet was successfully created.' }
        format.json { render :show, status: :created, location: @best_bet }
      else
        format.html { render :new }
        format.json { render json: @best_bet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /best_bets/1
  # PATCH/PUT /best_bets/1.json
  def update
    respond_to do |format|
      if @best_bet.update(best_bet_params)
        format.html { redirect_to @best_bet, notice: 'Best bet was successfully updated.' }
        format.json { render :show, status: :ok, location: @best_bet }
      else
        format.html { render :edit }
        format.json { render json: @best_bet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /best_bets/1
  # DELETE /best_bets/1.json
  def destroy
    @best_bet.destroy
    respond_to do |format|
      format.html { redirect_to best_bets_url, notice: 'Best bet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_best_bet
      @best_bet = BestBet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def best_bet_params
      params.require(:best_bet).permit(:title, :url, :description, :keywords)
    end


end
