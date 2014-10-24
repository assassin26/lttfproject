# encoding: UTF-8”

require 'google_drive'
class HoldgamesController < InheritedResources::Base

  before_filter :authenticate_user! , :except=>[:index,:show]
  before_filter :find_gameholder

  def index
   
    @holdgames=Holdgame.includes(:gameholder).where(:lttfgameflag=>true).where("startdate >= ? ", Time.zone.now.to_date-14).page(params[:page]).per(50)
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
 
  def create_gameinputfile(filename)
    connection = GoogleDrive.login(APP_CONFIG['Google_Account'], APP_CONFIG['Google_PWD'])
    folder = connection.collection_by_title(APP_CONFIG['Input_File_Folder'])
    spreadsheet = connection.spreadsheet_by_url(APP_CONFIG['Inupt_File_Template'])
    newspreadsheet=spreadsheet.duplicate(filename)
    folder.add(newspreadsheet)
    return newspreadsheet.human_url
  
  end

  private
  def find_gameholder

  	@cur_gameholder= Gameholder.where( :user_id=> current_user.id  ).first if current_user
  end	
end
