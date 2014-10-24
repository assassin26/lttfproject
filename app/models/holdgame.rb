#encoding: UTF-8”
class Holdgame < ActiveRecord::Base
  attr_accessible :enddate, :gameholder_id, :gamename, :gamenote, :gametype, :startdate , :contact_name
  attr_accessible :city, :county, :address, :zipcode, :courtname, :lat, :lng, :url , :lttfgameflag, :contact_phone , :contact_email
  attr_accessible :gameinfofile, :gamedays
  belongs_to :gameholder
  has_many :gamegroups , dependent: :destroy
  after_commit :assign_informs_from_holder
  scope :forgamesmaps, order(' zipcode ASC , startdate ASC ')
  default_scope  order('startdate DESC , zipcode ASC ')
  mount_uploader :gameinfofile,  GameInfofileUploader
  before_save :assign_enddate

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

end
