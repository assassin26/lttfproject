#encoding: UTF-8”
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
		skip_before_filter :authenticate_user!
	def facebook
		p env["omniauth.auth"]
		#user = User.from_omniauth(request.env["omniauth.auth"], current_user)
		user = User.from_omniauth(env["omniauth.auth"], current_user)
		if user && user.persisted?
			flash[:notice] = "您已成功從Facebook登入!"
			sign_in_and_redirect(user)
		else
			flash[:alert] = "無法從"+ env["omniauth.auth"]["info"]["name"]+"的Facebook帳號連結登入!如果您尚未設定Facebook帳號連結，請先進行連結設定!"
			#session["devise.user_attributes"] = user.attributes
			redirect_to new_user_session_path 
		end
	end
    
end