#encoding: UTF-8”
class Holdgame < ActiveRecord::Base
  attr_accessible :enddate, :gameholder_id, :gamename, :gamenote, :gametype, :startdate , :contact_name
  attr_accessible :city, :county, :address, :zipcode, :courtname, :lat, :lng, :url , :lttfgameflag, :contact_phone , :contact_email
  attr_accessible :gameinfofile, :gamedays
  belongs_to :gameholder
  has_many :gamecoholders ,dependent: :destroy
  has_many :gamegroups , dependent: :destroy
  has_one :uploadgame
  after_commit :assign_informs_from_holder
  scope :forgamesmaps, order(' zipcode ASC , startdate ASC ')
  default_scope  order('startdate ASC , zipcode ASC ')
  mount_uploader :gameinfofile,  GameInfofileUploader
  before_save :assign_enddate
  accepts_nested_attributes_for :gamecoholders, :allow_destroy => true
  def assign_enddate
     self.gamedays=1 if self.gamedays<=0 || !self.gamedays
     self.enddate=self.startdate+self.gamedays-1 
  end 

  def assign_informs_from_holder

    if self.lttfgameflag
  	  self.city=self.gameholder.city 
  	  self.county=self.gameholder.county 
  	  self.address=self.gameholder.address 
  	  self.courtname=self.gameholder.courtname
  	  self.zipcode=self.gameholder.zipcode
  	  self.lat=self.gameholder.lat
      self.lng=self.gameholder.lng
      self.contact_name=self.gameholder.name
      self.contact_phone=self.gameholder.phone
      self.contact_email=self.gameholder.email

   	  self.save
    else
      self.zipcode=TWZipCode_hash[self.city][self.county]
      self.save
    end  
  
  end	
  def find_player_ingroups_type(user_id)
    playergroups=Array.new
   
   
    self.gamegroups.each do |gamegroup|
  
    player_gattendant_id= gamegroup.find_player_in_attendants(user_id)
 
      if player_gattendant_id
      
        groups_type=Hash.new
        groups_type['group']=gamegroup
        groups_type['type']=gamegroup.find_official_backup_by_attendant_id(player_gattendant_id)
        playergroups.push(groups_type)
      end
      
    end 
   
    return playergroups 
  end 
  def find_gamecoholder(player_id)
      if self.gamecoholders.find_all{|v| v.co_holderid==player_id}.empty?
        return false
      else
        return true
      end 
  end  
end
