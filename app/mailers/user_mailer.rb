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
  def post_to_LTTF (messagetofb , nameoflink,pathlink, access_token)
    
    #oauth_access_token = access_token
    
    image_path = "#{Rails.root}/public/LTTF_logo.png"  #change to your image path
    message = messagetofb # your message
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
  def gamerecords_publish_notice ( user , gameplayer, gamesrecords ,gamename)
    @user = user
    @gameplayer=gameplayer
    @gamename=gamename
    @gamesrecords=gamesrecords
   
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核通知")

  end
  def gamerecords_publish_notice_to_FB ( gamename,access_token)
    
    @gamename=gamename
   
   
    #attachments["LTTF_logo.png"] = File.read("#{Rails.root}/public/LTTF_logo.png")
    #mail(:to => "lttf.taiwan@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    #mail(:to => "allen866129@gmail.com", :subject => "桌球愛好者聯盟#{gamename}比賽結果查核公告")
    @message="桌球愛好者聯盟#{gamename}比賽成績查核公告\n"+
          "各位盟友，#{gamename}比賽成績已開始公告查核作業\n"+
           "請參賽盟友儘速前往以下網址查核您的出賽成績。\n"+
           "如果您此次的比賽成績紀錄有誤，請儘速跟桌盟或主辦單位反應更正，以免影響正確的積分計算，謝謝配合。\n"+
           "桌球愛好者聯盟敬上"
    graph = Koala::Facebook::API.new(access_token )
    gamescorechecking_uploadgames_url
    graph.put_wall_post(@message, {   
     # "link" => "http://www.twlttf.org/lttfproject/uploadgames/gamescorechecking",
     "link" =>gamescorechecking_uploadgames_url,
      "description" =>"桌盟積分賽成績查核網頁" ,
      "name" =>"桌盟積分賽成績查核網頁",
      "picture" => "httP://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
      APP_CONFIG['LTTF_GROUP_ID']
     )
   
  end
  def newscore_publish_notice ( user , gameplayer, gamename)
    @user = user
    @gameplayer=gameplayer
    @gamename=gamename
    
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{gamename}積分更新通知")

  end
 def newscore_publish_notice_to_FB ( gamename,access_token)
    
    @gamename=gamename
    
    #mail(:to => "lttf.taiwan@gmail.com", :subject => "桌球愛好者聯盟#{gamename}積分更新公告")
    #mail(:to => "allen866129@gmail.com", :subject => "桌球愛好者聯盟#{gamename}積分更新公告")
    @message="桌球愛好者聯盟#{gamename}積分更新公告\n"+
          "各位盟友，#{gamename}比賽成績完成積分計算及積分更新作業\n"+
          "請參賽盟友可以前往桌盟積分賽網站查詢您最新的積分。\n"+
          "桌球愛好者聯盟敬上"

    graph = Koala::Facebook::API.new(access_token )
   
   
  
    graph.put_wall_post(@message, {   
    "link" => playerprofiles_url,
    "description" =>"桌盟積分賽球友積分總表",
    "name" =>"桌盟積分賽球友積分總表",
    "picture" => "http://www.twlttf.org/lttfproject/public/LTTF_logo.png"  },
    APP_CONFIG['LTTF_GROUP_ID']
     )  
 # post_to_LTTF(@message,@gamename, gamescorechecking_uploadgames_url,access_token)


  end
  def adjustscore_publish_notice ( user , gameplayer, gamename)
    @user = user
    @gameplayer=gameplayer
    @gamename=gamename
    @scorechange=gameplayer["adjustscore"].to_i-gameplayer["original bscore"].to_i
    mail(:to => "#{user.username} <#{user.email}>", :subject => "桌球愛好者聯盟#{gamename}通知")

  end
end