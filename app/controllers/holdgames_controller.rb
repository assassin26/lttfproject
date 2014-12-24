# encoding: UTF-8”

require 'google_drive'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
class HoldgamesController < InheritedResources::Base

  before_filter :authenticate_user! , :except=>[:index,:show]
  before_filter :find_gameholder

  def index
   
   if !params[:user]
      @allgames=true  #show all reg games
      @holdgames=Holdgame.includes(:gameholder).where(:lttfgameflag=>true).where("startdate >= ? ", Time.zone.now.to_date-14).page(params[:page]).per(50)
   else
      @allgames=false  #show all current_usr reg games
    @holdgames=Holdgame.includes(:gameholder).where(:lttfgameflag=>true,:gameholder_id=>params[:user].to_i).where("startdate >= ? ", Time.zone.now.to_date-14).page(params[:page]).per(50)
   end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @holdgames }
    end
  end
 
  def show
  	  @holdgame= Holdgame.find(params[:id])
  	  respond_to do |format|
        format.html # show.html.erb
        format.json { render json:@holdgame}
      end
  end 
  def new
  	#@holdgame = Holdgame.new(:gameholder_id => @cur_gameholder.id)
    @holdgame=@cur_gameholder.holdgames.build
    @holdgame.gamedays=1
    #@holdgame.url=holdgame_gamegroups_url(@holdgame)
  	 respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @holdgame }
    end
  end	
  def edit
  	 @holdgame = Holdgame.find(params[:id])
  	 respond_to do |format|
       format.html # show.html.erb
       format.json { render json: @holdgame}
     end
  end	
  def create

  	@holdgame = Holdgame.new(params[:holdgame])
    @holdgame.gameholder_id=@cur_gameholder.id
    @holdgame.lttfgameflag =true
    @holdgame.inputfileurl=create_gameinputfile(@holdgame.startdate.to_s+ @holdgame.gamename)
  	respond_to do |format|
      if @holdgame.save
        format.html { redirect_to holdgame_gamegroups_path(@holdgame), notice: '比賽資料建檔完成!' }
        format.json { render json: @holdgame, status: :created, location: @holdgame }
      else
        flash[:notice] = "比賽資料建檔資料失敗!"

        format.html { render action: "new", notice: '比賽資料建檔資料失敗，請跟管理員連絡辦理!' }
        format.json { render json: @holdgame.errors, status: :unprocessable_entity }
      end
    end
  end	

  def update
    @holdgame = Holdgame.find(params[:id])
    respond_to do |format|
      if @holdgame.update_attributes(params[:holdgame])
        format.html { redirect_to @holdgame, notice: '資料修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" ,notice: '資料修改失敗，請跟管理員連絡辦理!'}
        format.json { render json: @holdgame.errors, status: :unprocessable_entity }
      end
    end
  end
  def destroy
    @holdgame = Holdgame.find(params[:id])
    @holdgame.destroy

    respond_to do |format|
      format.html { redirect_to holdgames_url }
      format.json { head :no_content }
    end
  end
 
 ##
# Copy an existing file
#
# @param [Google::APIClient] client
#   Authorized client instance
# @param [String] origin_file_id
#   ID of the origin file to copy
# @param [String] copy_title
#   Title of the copy
# @return [Google::APIClient::Schema::Drive::V2::File]
#   The copied file if successful, nil otherwise
def copy_file(client, origin_file_id, copy_title)

  drive = client.discovered_api('drive', 'v2')
  copied_file = drive.files.copy.request_schema.new({
    'title' => copy_title
  })
  result = client.execute(
    :api_method => drive.files.copy,
    :body_object => copied_file,
    :parameters => { 'fileId' => origin_file_id })
  if result.status == 200
    return result.data
  else
    flash[:error]="An error occurred: #{result.data['error']['message']}"
  end
end
def create_gameinputfile(filename)
  client = Google::APIClient.new(
         :application_name => 'lttfprojecttest',
          :application_version => '1.0.0')
  fileid=APP_CONFIG['Inupt_File_Template'].to_s.match(/[-\w]{25,}/).to_s
  keypath = Rails.root.join('config','client.p12').to_s
  key = Google::APIClient::KeyUtils.load_from_pkcs12( keypath, 'notasecret')
  client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => 'https://www.googleapis.com/auth/drive',
    :issuer => APP_CONFIG[APP_CONFIG['HOST_TYPE']]['Google_Issuer'].to_s,
    :access_type => 'offline' ,
    :approval_prompt=>'force',
    :signing_key => key)
  client.authorization.fetch_access_token!
  fileinfo=copy_file(client, fileid, filename)

  fileinfo.alternateLink
  
end
  private
  def find_gameholder

  	@cur_gameholder= Gameholder.where( :user_id=> current_user.id  ).first if current_user
  end	
end
