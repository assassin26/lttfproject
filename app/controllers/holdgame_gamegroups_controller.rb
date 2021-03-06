# encoding: UTF-8”
class HoldgameGamegroupsController < ApplicationController
 before_filter :authenticate_user!, :except=>[:index,:teamplayersinput, :singleplayerinput, :doubleplayersinput, :cancel_player_registration, :update, :find_holdgame]
 layout :resolve_layout 
 before_filter :find_holdgame 



  def publishtoFB
    #if  current_user.authorizations.pluck(:provider).include?('facebook') 
      #UserMailer.newholdgame_publish_notice_to_FB( @holdgame,  session[:access_token]).deliver  if  session[:access_token] 
      #UserMailer.newholdgame_publish_notice_to_FB( @holdgame,  current_user.authorizations.where(:provider => 'facebook').last.token ).deliver   
      UserMailer.newholdgame_publish_notice_to_FB( @holdgame ).deliver     
      flash[:success]="已將本賽事公告於桌盟FB!"
    #else
    #   flash[:error]="請將您的桌盟帳號與FB帳號連結,才能執行此功能!"
    #end  
     redirect_to :action => "index"
  end 
def index

  if current_user
    gon.log_in = 1
    if !current_user.phone
       gon.nophone = 1
    end  
  else
    gon.log_in = 0
  end  
  @gamegroups = @holdgame.gamegroups
  if !params[:targroupid] && !@gamegroups.empty?
    @targetgroup_id=@gamegroups.first.id
   
    #@gamegroup=@holdgame.gamegroups.first
  else
    @targetgroup_id=params[:targroupid].to_i
  end 

  @player_current_score=Hash.new
  @groupaddtndant_registor_name=Hash.new
  @gamegroups.each do |gamegroup|
    gamegroup.allgroupattendee.flatten.each do |player|
      if player
         @player_current_score[player.player_id]=User.find(player.player_id).playerprofile.curscore 
      end   
    end
    if gamegroup.regtype=='team'
      gamegroup.groupattendants.each do |attendant|
        @groupaddtndant_registor_name[attendant.id]=User.find(attendant.registor_id).username
      end  
    end
  end
 
end
def create_attendee_array(gamegroups)
  @attendee_array=Hash.new
  @user_in_groups=Hash.new
  @user_current_score=Hash.new
  gamegroups.each do |gamegroup|
    @group_attendee_array=Array.new

    if(!gamegroup.groupattendants.empty? )
       
        gamegroup.groupattendants.each do |attendant|
          @temp=attendant.playerlist
          @group_attendee_array.push(@temp)
     
          user_in_group=@temp.find_all{|v|v['user_id']==current_user.id}
          if(!user_in_group.empty?)
            @user_in_groups[gamegroup.id]=attendant.id
          else
            @user_in_groups[gamegroup.id]=nil
          end  
         
      end  
    end

    
    @attendee_array[gamegroup.id]=@group_attendee_array
  end

  @attendee_array
end

def check_user_meetgroupqualify(gamegroups, player_id)
  user_meet_groups=Hash.new
  player=User.find(player_id)

  gamegroups.each do |gamegroup|
 
    user_meet_groups[gamegroup.id]=gamegroup.check_meet_group_qualify(player.playerprofile.curscore)
  end  
  return user_meet_groups
end

def preparesendmail
   @message= params[:message]
   @subject= params[:subject]
   @gamegroups = @holdgame.gamegroups
   gon.gamegroups=@gamegroups 
   @player_email=Hash.new
   @backupplayerlist=Array.new
   @gamegroups.each do |gamegroup|
     gamegroup.allgroupattendee.flatten.each do |player|
       @player_email[player.player_id]=false
     end 
      groupbackup=gamegroup.allgroupattendee.in_groups_of(gamegroup.noofplayers,false)[1]
      if groupbackup
        @backupplayerlist=@backupplayerlist+groupbackup.flatten 
      end  
   end
   gon.player_email=@player_email
   @backupplayerIDlist=Array.new
   @backupplayerlist.flatten.each do |player|
     @backupplayerIDlist.push(player.player_id.to_s) 

   end 

   gon.backupplayerlist=@backupplayerlist
   gon.backupplayerIDlist = @backupplayerIDlist
   #@groupttendee= @gamegroup.groupattendants
   #@attendee =@gamegroup.allgroupattendee
end 
def sendemail

  subject=params[:subject]
  message=params[:message]
  playersemail=params[:playersemail]
  @gamegroups = @holdgame.gamegroups
  @gamegroups.each do |gamegroup|
    gamegroup.allgroupattendee.flatten.each do |player|

      if player
        if  playersemail[player.player_id.to_s]=="1"
          UserMailer.sendgamenotice(@holdgame, player, subject,message).deliver   
        end 
      end 
     end 
   end
  flash[:success]="郵寄寄發作業已完成!"
  redirect_to  preparesendmail_holdgame_gamegroups_path(@holdgame, :subject=>subject , :message=>message)
end  

def registration

     @curgroup=Gamegroup.find(params[:format])
     attendantrecord=@curgroup.groupattendants.build
    
     Groupattendant.transaction do
     
     attendantrecord.regtype= @curgroup.regtype
     #attendantrecord.attendee='(,'+current_user.id.to_s+','+current_user.username+','+current_user.email+','+''+')'
     attendantrecord.phone=current_user.phone
     attendantrecord.registor_id=current_user.id
     if attendantrecord.save
       player=attendantrecord.attendants.build
       player.regtype=attendantrecord.regtype
       player.phone=attendantrecord.phone
        player.registor_id=attendantrecord.registor_id
        player.player_id=current_user.id
        player.name=current_user.username
        player.email=current_user.email
        player.curscore=current_user.playerprofile.curscore
        player.save
     end 
   end 

    #@gamegroups = @holdgame.gamegroups
    #@attendee=create_attendee_array(@gamegroups)
    #@targettabindex=@gamegroups.index(@curgroup)+1
   
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id})
end  
def singleregistration(group_id, playerids)
  
  @curgroup=Gamegroup.find(group_id)

  @playerlist=Array.new
  @playerlist=User.find(playerids) if playerids

  Groupattendant.transaction do
    @playerlist.each do |player| 
      attendantrecord=@curgroup.groupattendants.build 
      attendantrecord.regtype= @curgroup.regtype
      attendantrecord.phone=player.phone
      attendantrecord.registor_id=current_user.id
      if attendantrecord.save
        attendant=attendantrecord.attendants.build
        attendant.regtype=attendantrecord.regtype
        attendant.phone=attendantrecord.phone
        attendant.registor_id=attendantrecord.registor_id
        attendant.player_id=player.id
        attendant.name=player.username
        attendant.email=player.email
        attendant.curscore=player.playerprofile.curscore
        attendant.save
      end 
    end
   
  end 

end 

def doubleregistration(group_id, playerids)
  
  @curgroup=Gamegroup.find(group_id)

  @playerlist=Array.new
  @playerlist=User.where(:id=> playerids).order_by_ids(playerids).in_groups_of(2)
  Groupattendant.transaction do
     
   
    #attendantrecord.phone=current_user.phone
    #attendantrecord.registor_id=current_user.id
    
      @playerlist.each do |players|
        attendantrecord=@curgroup.groupattendants.build 
        attendantrecord.registor_id=current_user.id
        attendantrecord.regtype= @curgroup.regtype
        for player in players
          attendant=attendantrecord.attendants.build
          attendant.regtype=attendantrecord.regtype
          attendant.phone=player.phone
          attendant.registor_id=attendantrecord.registor_id
          attendant.player_id=player.id
          attendant.name=player.username
          attendant.email=player.email
          attendant.curscore=player.playerprofile.curscore
          attendant.save
        end
        attendantrecord.save
      end 
   
   
  end 
end  
def teamregistration(group_id, playerlist,teamname,old_attendantrecord)
  
  @curgroup=Gamegroup.find(group_id)
  if !old_attendantrecord
     attendantrecord=@curgroup.groupattendants.build 
  else
    attendantrecord=Groupattendant.find(old_attendantrecord) 
    attendantrecord.attendants.delete_all
  end  
  
  @playerlist=playerlist.in_groups_of(20,false) 
  Groupattendant.transaction do
     
    attendantrecord.regtype= @curgroup.regtype
    attendantrecord.phone=current_user.phone
    attendantrecord.registor_id=current_user.id
    attendantrecord.teamname=teamname
    if attendantrecord.save
      @playerlist.each do |players|
        for player in players
          attendant=attendantrecord.attendants.build
          attendant.regtype=attendantrecord.regtype
          attendant.phone=player.phone
          attendant.registor_id=attendantrecord.registor_id
          attendant.teamname=attendantrecord.teamname
          attendant.player_id=player.id
          attendant.name=player.username
          attendant.email=player.email
          attendant.curscore=player.playerprofile.curscore
          attendant.save
        end
      end 
    end
   
  end 

end  

def cancel_player_registration
    @attendantrecord=Groupattendant.find(params[:user_in_groupattendant])
    @curgroup=@attendantrecord.gamegroup
    @attendantrecord.destroy
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id})
end 
def cancel_player_registration_indouble
    
    @attendantrecord=Groupattendant.find(params[:user_in_groupattendant])
    @curgroup=@attendantrecord.gamegroup
    @attendantrecord.destroy
    #Attendant.where(:groupattendant_id=>params[:user_in_groupattendant],:player_id=>params[:player_id]).first.destroy
    #@attendantrecord.destroy
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id})
end


def cancel_player_registration_inteam
   
    @attendantrecord=Groupattendant.find(params[:user_in_groupattendant])
    @curgroup=@attendantrecord.gamegroup
    @tempattendant=Attendant.where(:groupattendant_id=>params[:user_in_groupattendant],:player_id=>params[:player_id]).first.destroy
    #@attendantrecord.destroy
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id})
end


 
def teamplayersinput
  successflag= false
  flash.clear
  @playerlist=Array.new
  @curgroup=Gamegroup.find(params[:format])
  #@playerlist=Array.new #to avoid pass nil array to view 
  if params[:registration]
    if params[:teamname]!=""
       @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
      #@playerlist=User.find(params[:playerid].uniq) if params[:playerid]
      scoresum=0
      @playerlist.each do |player|
        scoresum+=player.playerprofile.curscore
      end 
      
      if(!@curgroup.check_double_team_meet_group_qualify(scoresum))
        flash[:notice]='該組積分總和不符合本分組資格，無法接受報名!' 
      else
        successflag=true
        teamregistration(params[:format], @playerlist, params[:teamname],nil)
      end
    else
        @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
       #@curgroup=Gamegroup.find(params[:format])
       flash[:notice]='隊名不得為空白!請重新輸入'
    end 
                        
    elsif params[:quit]
      #@curgroup=Gamegroup.find(params[:format])
    
    elsif params[:getplayerfromuser] 
      if !params[:playerid] || params[:playerid].length<20
         @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
         #@curgroup=Gamegroup.find(params[:format])
         @teamname=params[:teamname]
        if params[:keyword] 
          @newplayer=get_inputplayer(params[:playerid],params[:keyword])
      
          if @newplayer  
            @playerlist.push(@newplayer)
          end  
        else
          flash[:notice]='球友資料皆不為空白!請重新輸入'
        end 
      else
         @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
         @curgroup=Gamegroup.find(params[:format])
         flash[:notice]='團隊球員不得超過20位!'
      end  
    end 
    
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id}) if (params[:registration]&&params[:teamname]!="" && successflag )  || params[:quit] || successflag      
end
def teamplayersadd
  successflag= false
  @curgroup=Gamegroup.find(params[:format])
  flash.clear
   if params[:name]=='add'
      @groupattendant_id=params[:row_group].to_i
      @teamname=Groupattendant.find(params[:row_group].to_i).teamname
      teamplayer_ids=params[:teamarray].collect{|s| s.to_i}
      curplayers=Attendant.find(teamplayer_ids).collect(&:player_id)
      #@playerlist=User.find( curplayers)
       @playerlist=User.where(:id=> curplayers).order_by_ids(curplayers) 
   else
     @groupattendant_id=params[:groupattendantid]
     @playerlist=Array.new #to avoid pass nil array to view
    end  
  if params[:registration]
    if params[:teamname]!=""
       @playerlist=Array.new
       @playerlist=User.where(:id=> params[:playerid]).order_by_ids(params[:playerid]) if params[:playerid]

       @playerscorelist=Array.new
       scoresum=0
       @playerlist.each do |player|
         scoresum+=player.playerprofile.curscore
       end  
   
       if(!@curgroup.check_double_team_meet_group_qualify(scoresum))
           flash[:notice]='該組積分總和不符合本分組資格，無法接受更改或新增!' 
         else
          successflag=true
          teamregistration(params[:format], @playerlist, params[:teamname],params[:groupattendantid])
        end
    else
       @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
     
       flash[:notice]='隊名不得為空白!請重新輸入'
    end 
                        
    elsif params[:quit]
      @curgroup=Gamegroup.find(params[:format])
    
    elsif params[:getplayerfromuser] 
      if !params[:playerid] || params[:playerid].length<20
         @playerlist=User.where(:id=> params[:playerid].uniq).order_by_ids(params[:playerid].uniq) if params[:playerid]
         @teamname=params[:teamname]
        if params[:keyword] 
          @newplayer=get_inputplayer(params[:playerid],params[:keyword])
      
          if @newplayer  
            @playerlist.push(@newplayer)
          end  
        else
          flash[:notice]='球友資料皆不為空白!請重新輸入'
        end 
      else
         @playerlist=User.find(params[:playerid].uniq) if params[:playerid]
         flash[:notice]='團隊球員不得超過20位!'
      end  
    end 
    
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id}) if (params[:registration]&&params[:teamname]!="" && successflag)  || params[:quit]      
end

def singleplayerinput
  flash.clear
  @playerlist=Array.new #to avoid pass nil array to view 
  if params[:registration]
     singleregistration(params[:format], params[:playerid].uniq)
     
                        
    elsif params[:quit]
      @curgroup=Gamegroup.find(params[:format])
    
    elsif params[:getplayerfromuser] 
      @playerlist=User.where(:id=> params[:playerid]).order_by_ids(params[:playerid]) if params[:playerid]
      @curgamegroupid=params[:format]
      @curgroup=Gamegroup.find(params[:format])
      if params[:keyword] 
        @newplayer=get_inputplayer(params[:playerid],params[:keyword])
      
        if @newplayer  
           @playerlist.push(@newplayer)
        end  
      else
        flash[:notice]='球友資料皆不為空白!請重新輸入'
      end 
   
    end 
    
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id}) if params[:registration] || params[:quit]      
end
def get_inputplayer(playerlist,keyword)

  if !keyword
     flash[:notice]='球友資料不得有空白!請重新輸入!'
     return nil
  end
  reg = /^\d+$/
  if ! reg.match(keyword)
    @newplayer = User.where(:username=>keyword).first
  else
    @newplayer=User.find_by_id(keyword.to_i)  
  end  
  if !@newplayer 
          flash[:notice] = "無此球友資料，請查明後再輸入!" 
    
  elsif(@curgroup.findplayer(@newplayer.id))
          flash[:notice] = "此球友已經完成報名，請勿重覆報名!"

  elsif playerlist && playerlist.include?(@newplayer.id.to_s)
          flash[:notice]="此球友("+@newplayer.id.to_s+","+@newplayer.username+")已經輸入，請勿重覆輸入!"
  elsif !@curgroup.check_single_meet_group_qualify(@newplayer.playerprofile.curscore) 
          flash[:notice] = "此球友("+@newplayer.id.to_s+","+@newplayer.username+","+@newplayer.playerprofile.curscore.to_s+ ")不符合此分組參賽資格，無法報名此分組比賽!"  
  else
    return @newplayer    
  end
  return nil      
end  

def doubleplayersinput
  flash.clear
  @playerlist=Array.new #to avoid pass nil array to view 
  if params[:registration]
    doubleregistration(params[:format], params[:playerid])
     
                        
    elsif params[:quit]
      @curgroup=Gamegroup.find(params[:format])
    
    elsif params[:getplayerfromuser] 

      @playerlist=Array.new
      #@playerlist=User.find(params[:playerid]) if params[:playerid]
      @playerlist=User.where(:id=> params[:playerid]).order_by_ids(params[:playerid]) if params[:playerid]#to keep same order
      @curgamegroupid=params[:format]
      @curgroup=Gamegroup.find(params[:format])

      if(params[:keyword1] && params[:keyword2])
        @newplayer1=get_inputplayer(params[:playerid],params[:keyword1])
        @newplayer2=get_inputplayer(params[:playerid],params[:keyword2])
        if @newplayer1 && @newplayer2
            if( !@curgroup.check_double_team_meet_group_qualify(@newplayer1.playerprofile.curscore+@newplayer2.playerprofile.curscore))
              flash[:notice]='該組積分總和不符合本分組資格，無法接受報名!' 
            else
              @playerlist.push( @newplayer1)
              @playerlist.push( @newplayer2)
            end
        end
        
      else
 
         flash[:notice]='因為是雙打賽,輸入兩位球友資料皆不得有空白!請重新輸入' 
      end  
      
    end 
    
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@curgroup.id}) if params[:registration] || params[:quit]      
   
end
def show

  @gamegroup = @holdgame.gamegroups.find( params[:format] )
  @groupttendee= @gamegroup.groupattendants
  @attendee =@gamegroup.allgroupattendee
end

def new
 
  @gamegroup = @holdgame.gamegroups.build
  @gamegroup.starttime=@holdgame.startdate.to_date
  @gamegroup.scorelow=0
  @gamegroup.scorehigh=2500

end

def create
  @gamegroup = @holdgame.gamegroups.build( params[:gamegroup] )
  if @gamegroup.save
  
     redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@gamegroup.id}) 
  else
    render :action => :new
  end
end

def edit

  @gamegroup = @holdgame.gamegroups.find( params[:id] )
  @gamegroup.starttime= @gamegroup.starttime.in_time_zone.strftime("%F %H:%M")

end

def update

  @gamegroup = @holdgame.gamegroups.find( params[:format] )

  if @gamegroup.update_attributes( params[:gamegroup] )
    redirect_to  holdgame_gamegroups_path(@holdgame, {:targroupid=>@gamegroup.id}) 
  else
    render :action => :edit
  end

end

def destroy
  @gamegroup = @holdgame.gamegroups.find( params[:id] )
  @gamegroup.groupattendants.delete_all
  @gamegroup.destroy

  redirect_to holdgame_gamegroups_url( @holdgame )
end
def groupdumptoxls

  @player_current_score=Hash.new
  @gamegroup = @holdgame.gamegroups.find( params[:gamegroup_id] )
  @gamegroup.allgroupattendee.flatten.each do |player|
      if player
         @player_current_score[player.player_id]=User.find(player.player_id).playerprofile.curscore 
      end   
  end
  @groupttendee= @gamegroup.groupattendants
  @attendee =@gamegroup.allgroupattendee
  filename=@holdgame.gamename+@gamegroup.groupname
  headers["Content-Disposition"] = "attachment; filename=\"#{filename}.xls\"" 
  respond_to do |format|
    format.xls 
  end
end  
protected

def find_holdgame
  @holdgame = Holdgame.find( params[:holdgame_id] )
  @gameholder=Gameholder.find( @holdgame.gameholder_id)
  gon.lat=@holdgame.lat
  gon.lng=@holdgame.lng
  gon.courtname=@holdgame.courtname+'--['+@holdgame.address+']'
end
def resolve_layout
    case action_name
    
    when "index" 
      "gamegroup"
    else
      "application"
    end
  end
end
