class GamesController < ApplicationController
  # GET /games
  # GET /games.json
  def index
    session[:player_id]="0"
    @games = Game.order(" created_at DESC").page(params[:page]).per(50)
    @gamescount=Game.all.size
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @games }
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show

    @game = Game.find(params[:id])

    @currentgamesummery=@game.players_result.split(/\n/)
    @playerssummery=Array.new

    @currentgamesummery.each do |playersummery|
      @players=Hash.new
      @dummy,@players["id"], @players["name"],@players["bgamescore"],@players["wongames"],@players["losegames"],@players["agamescore"],
                @players["scorechanged"]= playersummery.split("_")
      
      #@players["name"]=@playergameinfo[2]
      #@players["bgamescore"]=@playergameinfo[3]
      #@players["wongames"]=@playergameinfo[4]
      #@players["losegames"]=@playergameinfo[5]
      #@players["agamescore"]=@playergameinfo[6]
      #@players["scorechenged"]=@playergameinfo[7]
      @playerssummery.push(@players)
    end  

    @gamesrecords=Array.new
    @GameRawinfo=@game.detailgameinfo
    if(@GameRawinfo)
      @detailgamesrecord= @GameRawinfo.split("]")
     
      @detailgamesrecord.each do |singlegamerecord|
        @singlegame=singlegamerecord.split("|")
        if @singlegame.count==4 #old format
          @gamesarray=Hash.new
          @gamesarray["group"]=@singlegame[0]
          @players=@singlegame[1].split(":")
          @gamesarray["Aplayer"]=@players[0]
          @gamesarray["Bplayer"]=@players[1]
          @gamesarray["gameresult"]=@singlegame[2]
          @dummy,@gamesarray["detailrecords"] = @singlegame[3].split("[")
          @gamesarray["Players_scorechanged"]=nil
          @gamesrecords.push(@gamesarray)
        else     #new format count==5
          @gamesarray=Hash.new
          @gamesarray["group"]=@singlegame[0]
          @players=@singlegame[1].split(":")
          @gamesarray["Aplayer"]=@players[0]
          @gamesarray["Bplayer"]=@players[1]
          @gamesarray["gameresult"]=@singlegame[2]
          @gamesarray["Players_scorechanged"]=@singlegame[3].to_i
          @dummy,@gamesarray["detailrecords"] = @singlegame[4].split("[")
          @gamesrecords.push(@gamesarray)
         
        end  
          
      end
    end  
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @game }
    end
  end

  # GET /games/new
  # GET /games/new.json
  def new
    @game = Game.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @game }
    end
  end

  # GET /games/1/edit
  def edit
    @game = Game.find(params[:id])
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(params[:game])

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render json: @game, status: :created, location: @game }
      else
        format.html { render action: "new" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /games/1
  # PUT /games/1.json
  def update
    @game = Game.find(params[:id])

    respond_to do |format|
      if @game.update_attributes(params[:game])
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    respond_to do |format|
      format.html { redirect_to games_url }
      format.json { head :no_content }
    end
  end
end
