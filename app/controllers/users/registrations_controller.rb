class Users::RegistrationsController < Devise::RegistrationsController
def create
    super

     @newuser=resource
     
     #UserMailer.registration_confirmation(resource).deliver
      
     UserMailer.registration_confirmation(@newuser).deliver if !resource.errors.any? 
     
    
end

def update
  super
end
def cancelFBconnect
end	
def resetFBconnect
end	

end