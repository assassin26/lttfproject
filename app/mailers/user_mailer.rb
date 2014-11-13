  # encoding: UTF-8”
  class UserMailer < ActionMailer::Base
  default :from => "lttfadmin@twlttf.org"
  require 'koala'
  
  def sendgamenotice(holdgame,player,subject,message)
    @player=player
    @holdgame=holdgame
    @message=message
    mail(:to => "#{player.name} <#{player.email}>", :subject =>subject)
  end 
  def post_to_LTTF (messagetofb , nameoflink,pathlink)
    
    #oauth_access_token = access_token
    
    image_path = "#{Rails.root}/public/LTTF_logo.png"  #change to your image path
    message = messagetofb # your message
    @testuser=User.find(1)
    access_token=@testuser.authorizations.where(:provider => 'facebook').last.token
    graph = Koala::Facebook::API.new(access_token)
    graph = Koala::Facebook::API.new(access_token )
   
   
  
    graph.put_wall_post(messagetofb, {   
    "link" => "http://www.twlttf.org/lttfproject/uploadgames/gamescorechecking",
    "description" =>"桌盟積分賽成績查核網頁" ,
    "name" =>"桌盟積分賽成績查核網頁",
    "picture" => "httP://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
    APP_CONFIG['LTTF_GROUP_ID']
     )
    
  end           
  def registration_confirmation(user)
    @user = user
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟註冊完成通知")
  end
  def gamerecords_publish_notice ( user , gameplayer, gamesrecords ,holdgame)
    @user = user
    @gameplayer=gameplayer
    @gamename=holdgame.gamename
    @gamesrecords=gamesrecords
    @holdgame=holdgame
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{@gamename}比賽結果查核通知")

  end
  def gamerecords_publish_notice_to_FB ( uploadgame)
    
    @gamename=uploadgame.gamename
    @uploadgame=uploadgame
   
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    #mail(:to => "lttf.taiwan@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    #mail(:to => "allen866129@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    @message="桌球愛好者聯盟#{@gamename}比賽成績查核公告\n"+
          "各位盟友，#{@gamename}比賽成績已開始公告查核作業\n"+
           "請參賽盟友儘速前往以下網址查核您的出賽成績。\n"+
           "如果您此次的比賽成績紀錄有誤，請儘速跟桌盟或主辦單位反應更正，以免影響正確的積分計算，謝謝配合。\n"+
           "桌球愛好者聯盟敬上"
    @testuser=User.find(1)
    access_token=@testuser.authorizations.where(:provider => 'facebook').last.token
    graph = Koala::Facebook::API.new(access_token)
    graph.put_wall_post(@message, {   
     # "link" => "http://www.twlttf.org/lttfproject/uploadgames/gamescorechecking",
     #"link" =>gamescorechecking_uploadgames_url,
     "link" =>uploadgame_url(uploadgame),
      "description" =>uploadgame.gamename+"成績查核網頁" ,
      "name" =>uploadgame.gamename+"成績查核網頁" ,
      "picture" => "httP://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
      APP_CONFIG['LTTF_GROUP_ID']
     )
   
  end
  def getscorestring(gamegroup)
    case gamegroup.scorelimitation
      when '無積分限制'
       return '無'
      when '限制高低分' 
        return gamegroup.scorelow.to_s+'~'+gamegroup.scorehigh.to_s 
      when '限制最高分'
        return '小於'+gamegroup.scorehigh.to_s 
      when '限制最低分'
        return '大於'+gamegroup.scorelow.to_s
    end  
   
  end
 # def newholdgame_publish_notice_to_FB ( holdgame,access_token)
   def newholdgame_publish_notice_to_FB ( holdgame) 
    @gamename=holdgame.gamename
    @holdgame=holdgame
    @tempdategame=holdgame.startdate.to_s+holdgame.gamename
    @gameholdername=Gameholder.find(holdgame.gameholder_id).name
    @message="桌球愛好者聯盟新增賽事公告\n"+
          "各位盟友，#{@tempdategame}已開始接受報名。\n"+
          "此項賽事主辦人:#{@gameholdername}\n"+
           "請符合參賽資格且欲參賽之盟友儘速前往以下網址報名。\n"+
           "此項比賽分組如下\n"
          
    @gamegroups = @holdgame.gamegroups
    if !@gamegroups.empty?
        @gamegroups.each do |gamegroup|
          @message=@message+
                   "=======================\n"+
                   "組別:"+gamegroup.groupname+"\n"+
                   "賽制："+gamegroup.grouptype+"\n"+
                   "積分限制："+getscorestring(gamegroup)+"\n"+
                   "報名費用："+gamegroup.gamefee.to_s+"\n"+
                   "預計參賽人數："+gamegroup.noofplayers.to_s+"\n"+
                   "比賽時間："+gamegroup.starttime.strftime("%F %H:%M")+"\n"
        end  
    end  
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    #mail(:to => "lttf.taiwan@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    #mail(:to => "allen866129@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    @message=@message+ "桌球愛好者聯盟敬上"
    @testuser=User.find(1)
    access_token=@testuser.authorizations.where(:provider => 'facebook').last.token
    graph = Koala::Facebook::API.new(access_token)
   
   
    graph.put_wall_post(@message, {   
     # "link" => "http://www.twlttf.org/lttfproject/uploadgames/gamescorechecking",
     #"link" =>gamescorechecking_uploadgames_url,
    
     "link" =>holdgame_gamegroups_url(holdgame),
      "description" =>@tempdategame+"報名網頁" ,
      "name" =>@tempdategame+"報名網頁" ,
      "picture" => "httP://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
      APP_CONFIG['LTTF_GROUP_ID']
     )
   
  end
 
  def newscore_publish_notice ( user , gameplayer, gamename)
    @user = user
    @gameplayer=gameplayer
    @gamename=gamename
    
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{@gamename}積分更新通知")

  end
 def newscore_publish_notice_to_FB ( newgame)
    
    @gamename=newgame.gamename
    @newgame=newgame
    
    #mail(:to => "lttf.taiwan@gmail.com", :subject => "桌球愛好者聯盟#{gamename}積分更新公告")
    #mail(:to => "allen866129@gmail.com", :subject => "桌球愛好者聯盟#{gamename}積分更新公告")
    @message="桌球愛好者聯盟#{@gamename}積分更新公告\n"+
          "各位盟友，#{@gamename}比賽成績完成積分計算及積分更新作業\n"+
          "請參賽盟友可以前往桌盟積分賽網站查詢您最新的積分。\n"+
          "桌球愛好者聯盟敬上"
    @testuser=User.find(1)
    access_token=@testuser.authorizations.where(:provider => 'facebook').last.token
    graph = Koala::Facebook::API.new(access_token )
   
   
  
    graph.put_wall_post(@message, {   
    "link" => game_url(@newgame),
    "description" =>@gamename+"成績紀錄表",
    "name" =>@gamename+"成績紀錄表",
    "picture" => "http://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
    APP_CONFIG['LTTF_GROUP_ID']
     )  
 # post_to_LTTF(@message,@gamename, gamescorechecking_uploadgames_url,access_token)


  end
  def adjustscore_publish_notice ( user , gameplayer, uploadgame)
    @user = user
    @gameplayer=gameplayer
    @gamename=uploadgame.gamename
    @uploadgame=uploadgame
    @scorechange=gameplayer["adjustscore"].to_i-gameplayer["original bscore"].to_i
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{@gamename}通知")

  end
end