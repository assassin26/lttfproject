# encoding: UTF-8”
require 'google_drive'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

class Uploadgame < ActiveRecord::Base
  attr_accessible :detailgameinfo, :gamedate, :gamename, :originalfileurl, :players_result, :publishedforchecking, :uploader ,:id ,:scorecaculated ,:recorder ,:adjustplayersinfo
  scope :waitingforprocess, where( :scorecaculated => false )
  scope :finsihedprocess, where( :scorecaculated =>true )
  scope :waitingchecking, where( :scorecaculated => false ,:publishedforchecking=>true)
  belongs_to :holdgame
  def self.findlastrow(worksheet, targetcol)
    @ws_row=worksheet.num_rows
    loop do 
      break if worksheet[@ws_row,targetcol]!=""
      @ws_row-=1
    end
   
    @ws_row
  end	

  def self.GetBasicGameInfofromWs (newgame,gameinfows) 
    datereg=/^\d*\/\d{2}\/\d{4}$/
    tempdate=gameinfows[2,2].to_s
    tempdates=tempdate.split("/")
    tempdate=tempdates[2]+"-"+tempdates[0]+"-"+tempdates[1]
    newgame.gamedate=tempdate.to_date.strftime("%F")
    newgame.recorder=gameinfows[4,2]
    newgame
  end

  def self.GetPlayersinfo (gameinfows, oldplayerssummery)
    player_info_start_row =7
    @NoofPlayers= findlastrow(gameinfows,1) - player_info_start_row+1
  
    @CurGamePlayersInfo=Array.new
    (player_info_start_row..player_info_start_row+@NoofPlayers-1).each do |i|
      @Curplayer=Array.new(9)
      @Curplayer[0] = gameinfows[i,1] #serial
      @Curplayer[1] = gameinfows[i,2].strip #name
      Rails.logger.info(i.to_s)
      Rails.logger.info(@Curplayer[0].to_s)
      Rails.logger.info(@Curplayer[1])
      Rails.logger.info(@Curplayer[1].length)
      @Curprofile = Playerprofile.where( :name => @Curplayer[1] ).first
     
      @Curplayer[2]= @Curprofile.user_id #id
      @Curplayer[3] = @Curprofile.curscore #Bscore
      @Curplayer[3]=@Curprofile.initscore if @Curplayer[3]==nil

      @Curplayer[4] = 0  #Wongames
      @Curplayer[5] =0   #LoseGames
      @Curplayer[6] = 0  #AScore
      @Curplayer[7] = 0   #Scorechange

      if oldplayerssummery
        oldplayerinfo=@oldplayerssummery.find{|v| (v["id"]==@Curprofile.user_id)}
      end  
      @Curplayer[8] = (oldplayerinfo==nil) ? nil : oldplayerinfo["suggestscore"] #SuggestScore
      @Curplayer[9] = (oldplayerinfo==nil) ? nil : oldplayerinfo["adjustscore"] #adjustScore
      @Curplayer[10] = @Curprofile.curscore #original bgamescore without adjustment
      @CurGamePlayersInfo.push(@Curplayer)		
    end 
    @CurGamePlayersInfo		
  end
  def updatePlayerResultFromadjustPlayersinfo (adjustGamePlayersInfo)
     curlines=""
     adjustGamePlayersInfo.each do |player|
      curlines=curlines+ "\n" if curlines!=""   
      curlines=curlines+"_"+player["serial"].to_s 
      curlines=curlines+"_"+player["id"].to_s
      curlines=curlines+"_"+player["name"].to_s
      curlines=curlines+"_"+player["bgamescore"].to_s
      curlines=curlines+"_"+player["wongames"].to_s
      curlines=curlines+"_"+player["losegames"].to_s
      curlines=curlines+"_"+player["agamescore"].to_s
      curlines=curlines+"_"+player["scorechanged"].to_s
      curlines=curlines+"_"+player["suggestscore"].to_s
      curlines=curlines+"_"+player["adjustscore"].to_s
      curlines=curlines+"_"+player["original bscore"].to_s
    end
    self.players_result= curlines
  

  end
  def self.Processgamerocords(sheets)
    gameinfoheadrow=6
    gameinfoStartcol=13
    soruceGameRecordstartrow=7
    surrentgamerecordrow=soruceGameRecordstartrow
    gameplayercol=3
    resultcol=4
    winnercol=5
    gamerecordsstartcol=6
    playerNocol=2
  
    gamenamecol=gameinfoStartcol
    playerAcol=gameinfoStartcol+1
    playerBcol=playerAcol+1
    targetresultcol=playerBcol+1
    detailresultcol=targetresultcol+1
    playerinfostartrow=7
    @CurpageGames=Array.new
    regEx=/成績$/

    sheets.each do |ws|
   
      if regEx.match(ws.title)
         
        gameListA=Array.new
        gameListB=Array.new
        i=7
      
        while ( i < ws.num_rows )
       
          winnerNo=ws[i,winnercol]

          if (winnerNo!="NA")

            @SingleGame=Array.new(5)
       	    playerAno=ws[i,playerNocol]
            playerBno=ws[i+1,playerNocol]
       	    playerA =ws[i,gameplayercol].strip
       	    playerB =ws[i+1,gameplayercol].strip
       	    gamepointsA=ws[i,resultcol]
       	    gamepointsB=ws[i+1,resultcol]
       	    gameListA.clear
            gameListB.clear

       	    (0..4).each do |j|
              gameListA[j] = (ws[i,gamerecordsstartcol+j]=="")? "-" : ws[i,gamerecordsstartcol+j].to_s
              gameListB[j] = (ws[i+1,gamerecordsstartcol+j]=="")? "-" : ws[i+1,gamerecordsstartcol+j].to_s
            end 
            currecord=""
            if winnerNo==playerAno
              currecord= "["+ gameListA[0] + ":" + gameListB[0] + ";" + gameListA[1] + ":" + gameListB[1] + ";" + gameListA[2] + ":" + gameListB[2] + ";" + gameListA[3] + ":" + gameListB[3] + ";"  + gameListA[4] + ":" + gameListB[4]+"]"
            
              @SingleGame[0]=ws.title #0:group
              @SingleGame[1]=playerA #1:Winner
              @SingleGame[2]=playerB  #2 :Loser
              @SingleGame[3]= gamepointsA+":"+ gamepointsB   #3 :Gamepoint 
              @SingleGame[4]=currecord                #4 :gamedetail

            else
              currecord= "["+ gameListB[0] + ":" + gameListA[0] + ";" + gameListB[1] + ":" + gameListA[1] + ";" + gameListB[2] + ":" + gameListA[2] + ";" + gameListB[3] + ":" + gameListA[3] + ";"  + gameListB[4] + ":" + gameListA[4]+"]"
           
              @SingleGame[0]=ws.title
              @SingleGame[1]=playerB
              @SingleGame[2]=playerA
              @SingleGame[3]= gamepointsB+":"+ gamepointsA   
              @SingleGame[4]=currecord  

            end 
            @CurpageGames.push(@SingleGame)
          end 

          i += 2
        end
      
      end
    end
    @CurpageGames 
  end

  def self.calculate_score_change(ascore,bscore)
 
    if ascore<bscore          
      different=bscore-ascore
    
      case different
        when 0..12
          change=8
        when 13..37
          change=10
        when 38..62 
          change=13
        when 63..87
          change=16
        when 88..112   
          change=20
        when 113..137
          change=25
        when 138..162
          change=30
        when 163..187  
          change=35
        when 188..212
          change=40
        when 213..237
          change=45
        else
          change=50
      end

    else 

      different=ascore-bscore
      
      case different
        when 0..12
          change=8
        when 13..37
          change=7
        when 38..62
          change=6
        when 63..87
          change=5
        when 88..112
          change=4
        when 113..137
          change=3
        when 138..162  
          change=2
        when 163..187
          change=2
        when 188..212
          change=1
        when 213..237
          change=1
        else
         change=0
      end
   
    end
    change      
  end


  def self.combine_gamerecords(recordsarray)
    @fullgamerecords=""
	  recordsarray.each do |record|
      @fullgamerecords+=record[0]+"|"+record[1]+":"+record[2]+"|"+record[3]+"|"+record[4] 
  	end	
 	  @fullgamerecords
  end

  def self.calculate_score(players, gamerecords)
    players.each do |player|
      Rails.logger.info(player)
      @playerwongames=gamerecords.find_all{|v| v[1]==player[1]}
      if @playerwongames
  	    player[4]+=@playerwongames.length
    
        @playerwongames.each do |wongame|
          Rails.logger.info(wongame)
          opplayer=players.find{|e| e[1]==wongame[2]}
           Rails.logger.info(opplayer)
          player[7]+=calculate_score_change( player[3].to_i,opplayer[3].to_i)
        
        end
      end 
  	  @playerlosegames=gamerecords.find_all{|v| v[2]==player[1]}
      if @playerlosegames
  	    player[5]+=@playerlosegames.length

  	    @playerlosegames.each do |losegame|
         Rails.logger.info(losegame)
          opplayer=players.find{|e| e[1]==losegame[1]}
           Rails.logger.info(opplayer)
          player[7]-=calculate_score_change( opplayer[3].to_i,player[3].to_i)
        
        end
      
      end
      Rails.logger.info(player)
      player[6]=player[3]+player[7]
    end	

    players
  end	
  def self.hash_calculate_score(players, gamerecords)
    players.each do |player|
      player["scorechanged"]=0
      player["agamescore"]=0
      @playerwongames=gamerecords.find_all{|v| v["Aplayer"]==player["name"]}
      player["wongames"] += @playerwongames.length
      @playerwongames.each do |wongame|
       
        opplayer=players.find{|e| e["name"]==wongame["Bplayer"]}
        player["scorechanged"]+=calculate_score_change( player["bgamescore"].to_i,opplayer["bgamescore"].to_i)
       
   
       end 
      @playerlosegames=gamerecords.find_all{|v| v["Bplayer"]==player["name"]}
      player["losegames"]+=@playerlosegames.length

      @playerlosegames.each do |losegame|
      
        opplayer=players.find{|e| e["name"]==losegame["Aplayer"]}
        player["scorechanged"]-=calculate_score_change( opplayer["bgamescore"].to_i,player["bgamescore"].to_i)
          
      end
      
      player["agamescore"]=player["bgamescore"].to_i+ player["scorechanged"].to_i
    
    end 

    players
  end 
 def getplayersummary
    return nil if !self.players_result
    @currentgamesummery= self.players_result.split(/\n/)
    @playerssummery=Array.new

    @currentgamesummery.each do |playersummery|
      @player=Hash.new
      @dummy,@player["serial"],@player["id"], @player["name"],@player["bgamescore"],@player["wongames"],@player["losegames"],@player["agamescore"],
                @player["scorechanged"],@player["suggestscore"],@player["adjustscore"],@player["original bscore"]= playersummery.split("_")
      @player["id"]=@player["id"].to_i
      @player["bgamescore"]=@player["bgamescore"].to_i
      @player["wongames"]=@player["wongames"].to_i
      @player["losegames"]=@player["losegames"].to_i
      @player["agamescore"]=@player["agamescore"].to_i
      @player["scorechanged"]=@player["scorechanged"].to_i
      @player["suggestscore"]=@player["suggestscore"].to_i
      @player["adjustscore"]=@player["adjustscore"].to_i if @player["adjustscore"]!=nil
      @player["original bscore"]=@player["original bscore"].to_i if @player["original bscore"]!=nil
      @playerssummery.push(@player)
    end  
    @playerssummery  
  end 

  def getdetailgamesrecord

    gamesrecords=Array.new
        
    detailgamesrecord= self.detailgameinfo.split("]")
     

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
  def self.upload(holdgame)
   client = Google::APIClient.new(
         :application_name => 'lttfprojecttest',
          :application_version => '1.0.0')
   #fileid=APP_CONFIG['Inupt_File_Template'].to_s.match(/[-\w]{25,}/).to_s
   
    keypath = Rails.root.join('config','client.p12').to_s
    key = Google::APIClient::KeyUtils.load_from_pkcs12( keypath, 'notasecret')
    client.authorization = Signet::OAuth2::Client.new(
     :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
     :audience => 'https://accounts.google.com/o/oauth2/token',
     :scope => 'https://spreadsheets.google.com/feeds/',
     :issuer => APP_CONFIG[APP_CONFIG['HOST_TYPE']]['Google_Issuer'].to_s,
     :access_type => 'offline' ,
     :approval_prompt=>'force',
     :signing_key => key)
     client.authorization.fetch_access_token!
 
    connection = GoogleDrive.login_with_oauth( client.authorization.access_token)
	  #@newgame=Uploadgame.new
    spreadsheet = connection.spreadsheet_by_url(holdgame.inputfileurl)
    
    @newgame =   (holdgame.uploadgame==nil) ? holdgame.build_uploadgame : holdgame.uploadgame
    #@newgame=Uploadgame.waitingforprocess.where(:gamename => holdgame.gamename).first_or_initialize
   
    @oldplayerssummery=@newgame.getplayersummary
    @newgame.gamename =spreadsheet.title()
    @gameinfows=spreadsheet.worksheets[0] 
    @newgame=GetBasicGameInfofromWs(@newgame, @gameinfows)
    @CurPlayersInfo=GetPlayersinfo(@gameinfows,@oldplayerssummery)
    
    @Gamerecords= Processgamerocords(spreadsheet.worksheets)
   
    @newgame.detailgameinfo=combine_gamerecords(@Gamerecords)
    @CurPlayersInfo=calculate_score(@CurPlayersInfo , @Gamerecords)
    
    curlines=""
    
    @CurPlayersInfo.each do |player|
      
  
      curlines=curlines+ "\n" if curlines!="" 	
      curlines=curlines+"_"+player[0].to_s 
      curlines=curlines+"_"+player[2].to_s
      curlines=curlines+"_"+player[1]
      curlines=curlines+"_"+player[3].to_s
      curlines=curlines+"_"+player[4].to_s
      curlines=curlines+"_"+player[5].to_s
      curlines=curlines+"_"+player[6].to_s
      curlines=curlines+"_"+player[7].to_s
      curlines=curlines+"_"+player[8].to_s
      curlines=curlines+"_"+player[9].to_s
      curlines=curlines+"_"+player[10].to_s
    end
    @newgame.players_result= curlines
    @newgame.scorecaculated=false 
    @newgame 
  end	
 
end
