# encoding: UTF-8”
class Gamegroup < ActiveRecord::Base
  attr_accessible :gamefee, :groupname, :grouptype, :holdgame_id, :noofbackupplayers, :noofplayers, :scorehigh
  attr_accessible :scorelimitation, :scorelow, :starttime , :regtype
  belongs_to :holdgame
  has_many :groupattendants, dependent: :destroy
  default_scope order('id ASC')
  def self.regtypes
   {'single'=>'個人', 'double'=>'雙人', 'team'=>'團體'}
  end
  def find_player_in_attendants(player_id)
  	self.groupattendants.each do |attendee|
  	  if attendee.findplayer(player_id)
  	    return attendee.id 
  	  end 	
  	end	
  	return nil
  end
  def check_meet_group_qualify(player_curscore)
    return true if player_curscore==0
      
  	case self.scorelimitation
      when '無積分限制'
         return true
      when '限制高低分'
       return( (player_curscore >= self.scorelow) &&
            (player_curscore<=self.scorehigh) )
      when '限制最高分'
         return (player_curscore<=self.scorehigh) 
      when '限制最低分'                                    
        return (player_curscore>=self.scorelow) 
    end	
  end
  def allgroupattendee
    case self.regtype
      when 'single'
        playerlist=Array.new
        self.groupattendants.each do |attendrecord|
          playerlist=playerlist+attendrecord.attendants
        end  
        return playerlist
      when 'double' 
        playerlist=Array.new
        self.groupattendants.each do |attendrecord|
          playerlist=playerlist+attendrecord.attendants.in_groups_of(2) 
        end 
        return playerlist
      when 'team' 
        playerlist=Array.new
        self.groupattendants.each do |attendrecord|
        playerlist=playerlist+attendrecord.attendants.in_groups_of(20,false) 
        end 
        return playerlist 
    end
  end

  def findplayer(player_id)

    self.groupattendants.each do |attendrecord|
     return true if attendrecord.findplayer(player_id)  
    end 
    false 
  end
  def check_official(player_id)
    
  end
  def totalresgisteredsplayersno
   
    return self.groupattendants.length
     
  end
end
