# encoding: UTF-8”
class UploadgamesController < ApplicationController
  before_filter :authenticate_user! ,:except=>[:gamescorechecking, :show]
  before_filter :facebook_auth

   # GET /uploadgames
  # GET /uploadgames.json
  require "koala"
 def facebook_auth
      uri= callback_uploadgames_url
      if current_user && ((current_user.has_role? :superuser) || (current_user.has_role? :admin)) && !session[:access_token]
        #session[:oauth]= Koala::Facebook::OAuth.new(APP_CONFIG[APP_CONFIG['HOST_TYPE']]['APP_ID'].to_s, APP_CONFIG[APP_CONFIG['HOST_TYPE']]['APP_SECRET'],APP_CONFIG[APP_CONFIG['HOST_TYPE']]['REDIRECT_URI_Uploadgames'])
        session[:oauth]= Koala::Facebook::OAuth.new(APP_CONFIG[APP_CONFIG['HOST_TYPE']]['APP_ID'].to_s, APP_CONFIG[APP_CONFIG['HOST_TYPE']]['APP_SECRET'],uri)
        @auth_url =  session[:oauth].url_for_oauth_code(:permissions=> " manage_pages,publish_stream,user_groups,publish_actions")  
     
      end
    
  end
  def callback
   
    if params[:code] 
     session[:access_token] = session[:oauth].get_access_token(params[:code])
    end 
    
     @uploadgames = Uploadgame.waitingforprocess.page(params[:page]).per(10)
     redirect_to :action => "index"
  end
  def index
  
      if current_user 
        return redirect_to(@auth_url)   if ( (current_user.has_role? :superuser) || (current_user.has_role? :admin)) && !session[:access_token]
      end  
  
    @uploadgames = Uploadgame.waitingforprocess.page(params[:page]).per(10)
   
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @uploadgames }
    end
  end
  
  def gamescorechecking
    @uploadgames = Uploadgame.waitingchecking.page(params[:page]).per(10)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @uploadgames }
    end
  end

  def savetoupload
    
   
    @cacheuploadgame=Rails.cache.read("curgame")
    Uploadgame.transaction do
      Uploadgame.waitingforprocess.where(:gamename => @cacheuploadgame.gamename).destroy_all 
      @uploadgame=Uploadgame.new
      @uploadgame= @cacheuploadgame
      @playerssummery=Rails.cache.read("playersummery")
      i=0
      params[:suggestscore].each do |suggestscore|
        @playerssummery[i]["suggestscore"]=suggestscore
        i+=1
      end  
      curlines=""
      @playerssummery.each do |player|

        curlines=curlines+ "\n" if curlines!=""   
        curlines=curlines+"_"+player["serial"].to_s 
        curlines=curlines+"_"+player["id"].to_s
        curlines=curlines+"_"+player["name"]
        curlines=curlines+"_"+player["bgamescore"].to_s
        curlines=curlines+"_"+player["wongames"].to_s
        curlines=curlines+"_"+player["losegames"].to_s
        curlines=curlines+"_"+player["agamescore"].to_s
        curlines=curlines+"_"+player["scorechanged"].to_s
        curlines=curlines+"_"+player["suggestscore"].to_s
        curlines=curlines+"_"+player["adjustscore"].to_s
     
      end
      @uploadgame.players_result= curlines   
      @uploadgame.uploader=current_user.username

      @uploadgame.save! 
    end  
    flash[:alert] = "檔案上傳成功"
    @uploadgames =  Uploadgame.waitingforprocess.page(params[:page]).per(10)
    redirect_to :action => "index"
  end 

  def upload
    
        
  end

  def displayuploadfile
    
    @uploadgame=Uploadgame.upload(params[:gamefileurl])
    #@uploadgame =  Uploadgame.last
    @playerssummery=getplayersummary(@uploadgame.players_result)
    #@playerssummery=@NewFoo.uploadplayerinfo
   
   
    @gamesrecords=getdetailgamesrecord(@uploadgame.detailgameinfo)
    #@gamesrecords=@NewFoo.uploadgamesrecord

    Rails.cache.write("curgame", @uploadgame)
    Rails.cache.write("playersummery",@playerssummery)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @uploadgame }
    end
  end  
  def uploadfile_fromholdgame

    holdgame=Holdgame.find(params[:format])

    @uploadgame=Uploadgame.upload(holdgame.inputfileurl)
    #@uploadgame =  Uploadgame.last
    @playerssummery=getplayersummary(@uploadgame.players_result)
    #@playerssummery=@NewFoo.uploadplayerinfo
   
   
    @gamesrecords=getdetailgamesrecord(@uploadgame.detailgameinfo)
    #@gamesrecords=@NewFoo.uploadgamesrecord

    Rails.cache.write("curgame", @uploadgame)
    Rails.cache.write("playersummery",@playerssummery)
    render :displayuploadfile
  end  

  def getplayersummary(players_result)
    @currentgamesummery= players_result.split(/\n/)
    @playerssummery=Array.new

    @currentgamesummery.each do |playersummery|
      @player=Hash.new
      @dummy,@player["serial"],@player["id"], @player["name"],@player["bgamescore"],@player["wongames"],@player["losegames"],@player["agamescore"],
                @player["scorechanged"],@player["suggestscore"],@player["adjustscore"]= playersummery.split("_")
      @player["id"]=@player["id"].to_i
      @player["bgamescore"]=@player["bgamescore"].to_i
      @player["wongames"]=@player["wongames"].to_i
      @player["losegames"]=@player["losegames"].to_i
      @player["agamescore"]=@player["agamescore"].to_i
      @player["scorechanged"]=@player["scorechanged"].to_i
      @player["suggestscore"]=@player["suggestscore"].to_i
      @player["adjustscore"]=@player["adjustscore"].to_i if @player["adjustscore"]!=nil
      @playerssummery.push(@player)
    end  
    @playerssummery  
  end  

  def getdetailgamesrecord(gameRawinfo)
    gamesrecords=Array.new
    
    if(gameRawinfo)
      detailgamesrecord= gameRawinfo.split("]")
    end  

    detailgamesrecord.each do |singlegamerecord|
    
      singlegame=singlegamerecord.split("|")
      gamesarray=Hash.new
      gamesarray["group"]=singlegame[0]
      players=singlegame[1].split(":")
      gamesarray["Aplayer"]=players[0]
      gamesarray["Bplayer"]=players[1]
      gamesarray["gameresult"]=singlegame[2]
      dummy,gamesarray["detailrecords"] = singlegame[3].split("[")
      gamesrecords.push(gamesarray)
    end
    gamesrecords
  end  
  
  # GET /uploadgames/1
  # GET /uploadgames/1.json
  def show
    @uploadgame = Uploadgame.find(params[:id])
       
    @playerssummery=getplayersummary(@uploadgame.players_result)
    @gamesrecords=getdetailgamesrecord(@uploadgame.detailgameinfo)
    

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @uploadgame }
    end
  end
  def send_publish_notice_to_players(uploadgame) 
    @playerssummery=getplayersummary(uploadgame.players_result)
    @gamesrecords=getdetailgamesrecord(uploadgame.detailgameinfo)
    @playerssummery.each do |player|
      @playergames=@gamesrecords.find_all{|v| (v["Aplayer"]==player["name"])||(v["Bplayer"]==player["name"])}
      @user=User.find(player["id"].to_i)
      @player=player
      UserMailer.gamerecords_publish_notice(@user, @player, @playergames, uploadgame).deliver
     
    end  
     
     UserMailer.gamerecords_publish_notice_to_FB( uploadgame,  session[:access_token]).deliver  if  session[:access_token]
  end
  def publishuploadgame

    @uploadgame = Uploadgame.find(params[:game_id])
       
    @uploadgame.publishedforchecking = true
    @uploadgame.save
    send_publish_notice_to_players(@uploadgame)
   

    @uploadgames = Uploadgame.waitingforprocess.page(params[:page]).per(10)
    redirect_to :action => "index"
    
  end
def updategamescore_to_main_table (uploadgame, inp_adjustplayers)
    adjustplayers= inp_adjustplayers.find_all{|v| !(v["wongames"]==0 && v["losegames"]==0) }
   
    playersadjusted= Array.new
    curlines=""
    date = DateTime.now
    User.transaction do
      adjustplayers.each  do |player|
        @player=User.find(player["id"].to_i)
        if player["bgamescore"]!= player["original bscore"]  #賽前積分不等候原來績分,表示需前作調整
          if @player.playerprofile.initscore ==0        #初始積分為0,前置調整當作賦予初始積分不是前置調整
            @player.playerprofile.initscore=player["bgamescore"].to_i 
            predate=date-1
            @player.playerprofile.gamehistory=predate.to_date.to_s+"("+player["bgamescore"].to_s+")" #將initscore設定時間提前一天,讓趨勢圖更容易顯示
          else
            curlines=curlines+ "\n" if curlines!=""   
            curlines=curlines+"_"+player["id"].to_s
            curlines=curlines+"_"+player["name"]
            curlines=curlines+"_"+player["original bscore"].to_s
            curlines=curlines+"_"+"0"
            curlines=curlines+"_"+"0"
            curlines=curlines+"_"+player["bgamescore"].to_s
            scorechange=player["bgamescore"].to_i-player["original bscore"].to_i
            curlines=curlines+"_"+scorechange.to_s
            @player.playerprofile.curscore=player["agamescore"].to_i
            @player.playerprofile.lastscoreupdatedate =date.to_date.to_s
            @player.playerprofile.gamehistory=@player.playerprofile.gamehistory+"\n"+date.to_date.to_s+"("+player["agamescore"].to_s+")" 
         
          end
          @player.save 
          @playerscore=player 
          UserMailer.adjustscore_publish_notice(@player,@playerscore,@uploadgame).deliver
        end
      end
    end
    if curlines !=""
      @adjustgame=Game.new
      @adjustgame.gamedate=date.to_date.to_s
      @adjustgame.gamename=uploadgame.gamename+"前置調整"
      @adjustgame.players_result=curlines
      @adjustgame.uploader="LTTF"
      @adjustgame.save
    end  
    @newgame=Game.new
    @newgame.gamename=uploadgame.gamename
    @newgame.detailgameinfo=uploadgame.detailgameinfo
    @newgame.uploader=uploadgame.uploader
    curlines=""
    User.transaction do
      adjustplayers.each  do |player|
        if !(player["wongames"]==0 && player["losegames"]==0) 
          curlines=curlines+ "\n" if curlines!=""   
          curlines=curlines+"_"+player["id"].to_s
          curlines=curlines+"_"+player["name"]
          curlines=curlines+"_"+player["bgamescore"].to_s
          curlines=curlines+"_"+player["wongames"].to_s
          curlines=curlines+"_"+player["losegames"].to_s
          curlines=curlines+"_"+player["agamescore"].to_s
          curlines=curlines+"_"+player["scorechanged"].to_s
          @player=User.find(player["id"])
          @player.playerprofile.curscore=player["agamescore"].to_i

          @player.playerprofile.totalwongames =0 if !@player.playerprofile.totalwongames
          @player.playerprofile.totalwongames+=player["wongames"].to_i
          @player.playerprofile.totallosegames =0 if !@player.playerprofile.totallosegames
          @player.playerprofile.totallosegames+=player["losegames"].to_i
          @player.playerprofile.lastgamedate =uploadgame.gamedate
          @player.playerprofile.lastgamename =uploadgame.gamename
          @player.playerprofile.lastscoreupdatedate =date.to_date.to_s

          if @player.playerprofile.gamehistory==nil 
            if player["initscore"]!=0
              @player.playerprofile.gamehistory= @player.playerprofile.created_at.to_date.to_s+"("+ @player.playerprofile.initscore.to_s+")" 
              @player.playerprofile.gamehistory=@player.playerprofile.gamehistory+"\n"+date.to_date.to_s+"("+player["agamescore"].to_s+")" 
            else
               @player.playerprofile.gamehistory=date.to_date.to_s+"("+player["agamescore"].to_s+")" 
            end 
          else
               @player.playerprofile.gamehistory=@player.playerprofile.gamehistory+"\n"+date.to_date.to_s+"("+player["agamescore"].to_s+")" 
          end  

          @player.save
          @playerscore=player
          UserMailer.newscore_publish_notice(@player,@playerscore,@uploadgame.gamename).deliver
        end
      end
    end
     @newgame.players_result=curlines  
     @newgame.save
     UserMailer.newscore_publish_notice_to_FB( @newgame,  session[:access_token]).deliver  if session[:access_token]
  end  
 
  def trycalculation
   # @uploadgame = Uploadgame.find(params[:game_id])
    @uploadgame=Rails.cache.read("curgame")
    @playerssummery=Rails.cache.read("playersummery")
    @gamesrecords=Rails.cache.read("gamesrecords")
    @adjustplayers=Rails.cache.read("adjustplayers")
   
    i=0
    #params[:adjustscores].each do |adjustscore|
    @adjustplayers.each do |adjustplayer|  
    adjustplayer["adjustscore"]=params[:adjustscores][i]
    adjustplayer["bgamescore"]=adjustplayer["original bscore"]
    i+=1
      
    end  
    @adjustplayers=set_adjust_players(@adjustplayers)
    @adjustplayers=Uploadgame.hash_calculate_score(@adjustplayers, @gamesrecords)
    #@zeroscoreplayers= @adjustplayers.find_all{|v| v["bgamescore"].to_i==0 ||v["bgamescore"]=="" }
    @zeroscoreplayers= @adjustplayers.find_all{|v| (v["bgamescore"].to_i==0 ||v["bgamescore"]=="") && (v["adjustscore"]==nil ||v["adjustscore"]=="") && !(v["wongames"]==0 && v["losegames"]==0)}
    flash[:alert]=""
    flash[:alert]="尚有0積分球友，需賦予調整積分才可進行積分更新作業!"  if  @zeroscoreplayers!=[]
    Rails.cache.write("adjustplayers",@adjustplayers)
    Rails.cache.write("curgame", @uploadgame)
    Rails.cache.write("playersummery",@playerssummery)
   if params[:save_option_a]
       render :calculategamepage 
       
    end
    if params[:save_option_b]
   
      Uploadgame.transaction do
        @uploadgameinDB = Uploadgame.waitingforprocess.find_by_id( @uploadgame.id)
        if @uploadgameinDB
          updategamescore_to_main_table(@uploadgame,@adjustplayers)
          #@uploadgame = Uploadgame.find( @uploadgame.id)
          @uploadgameinDB.scorecaculated =true
          @uploadgameinDB.save
        end
      end
      @uploadgames = Uploadgame.waitingforprocess.page(params[:page]).per(10)
      flash[:success]="積分更新作業完成!"
       redirect_to :action => "index"
    end
  end

  def wirte_caculatedscore_to_DB
      
  end  

  def set_adjust_players(playersinfo)
    @adjustplayers = Array.new
    playersinfo.each do |player|
      adjustplayer= Hash.new()
      adjustplayer = player
      adjustplayer["serial"]=player["serial"]
      adjustplayer["id"]=player["id"]
      adjustplayer["name"]=player["name"]
      adjustplayer["original bscore"]=player["bgamescore"]
      adjustplayer["bgamescore"]=player["adjustscore"].to_i if (player["adjustscore"]!="" && player["adjustscore"]!=nil)
      adjustplayer["wongames"]=0
      adjustplayer["losegames"]=0
      adjustplayer["scorechanged"]=0
      adjustplayer["agamescore"]=0
      @adjustplayers.push(adjustplayer)    
    end  
    @adjustplayers
  end  

  def calculategamepage
    
     @uploadgame = Uploadgame.find(params[:game_id])
     @playerssummery=getplayersummary(@uploadgame.players_result)
     @gamesrecords=getdetailgamesrecord(@uploadgame.detailgameinfo)
     @adjustplayers=set_adjust_players(@playerssummery)
     @adjustplayers=Uploadgame.hash_calculate_score(@adjustplayers, @gamesrecords)
     @zeroscoreplayers= @adjustplayers.find_all{|v| (v["bgamescore"].to_i==0 ||v["bgamescore"]=="") && (v["adjustscore"]==nil ||v["adjustscore"]=="") && !(v["wongames"]==0 && v["losegames"]==0)}
     flash[:alert]="尚有0積分球友，需賦予調整積分才可進行積分更新作業!"  if  @zeroscoreplayers!=[]
     Rails.cache.write("curgame", @uploadgame)
     Rails.cache.write("playersummery",@playerssummery)
     Rails.cache.write("gamesrecords",@gamesrecords)
     Rails.cache.write("adjustplayers",@adjustplayers)
  end   
  # GET /uploadgames/new
  # GET /uploadgames/new.json
  def new
    @uploadgame = Uploadgame.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @uploadgame }
    end
  end

  # GET /uploadgames/1/edit
  def edit
    @uploadgame = Uploadgame.find(params[:id])
  end

  # POST /uploadgames
  # POST /uploadgames.json
  def create
    @uploadgame = Uploadgame.new(params[:uploadgame])

    respond_to do |format|
      if @uploadgame.save
        format.html { redirect_to @uploadgame, notice: 'Uploadgame was successfully created.' }
        format.json { render json: @uploadgame, status: :created, location: @uploadgame }
      else
        format.html { render action: "new" }
        format.json { render json: @uploadgame.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /uploadgames/1
  # PUT /uploadgames/1.json
  def update
    @uploadgame = Uploadgame.find(params[:id])

    respond_to do |format|
      if @uploadgame.update_attributes(params[:uploadgame])
        format.html { redirect_to @uploadgame, notice: 'Uploadgame was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @uploadgame.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /uploadgames/1
  # DELETE /uploadgames/1.json
  def destroy
    @uploadgame = Uploadgame.find(params[:id])
    @uploadgame.destroy

    respond_to do |format|
      format.html { redirect_to uploadgames_url }
      format.json { head :no_content }
    end
  end
end
