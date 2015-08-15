class ReportsController < ApplicationController
  before_action :set_report, only: [:show, :edit, :update, :destroy]

  # GET /reports
  # GET /reports.json
  def index
    
    params[:crop] ||= "Maize"
    params[:statistic] ||= "Yield"
    
    crop = params[:crop]
    stat = params[:statistic]
    
    @reports = Report.where(crop: crop.capitalize, statistic: stat.capitalize)
    @estimate = TextMessage.stats([crop,stat,"Thies"])
    
    #@values = @reports.map(&:value)
    #@mean = ::CropModule::Maths.mean(@values)
    #@mean = 0 if @mean.nan?
    #@sd = ::CropModule::Maths.standard_deviation(@values)
    #@sd = 0 if @sd.nan?
  end

  # GET /reports/1
  # GET /reports/1.json
  def show
  end

  # GET /reports/new
  def new
    @report = Report.new
  end

  # GET /reports/1/edit
  def edit
  end

  # POST /reports
  # POST /reports.json
  def create
    @report = Report.new(report_params)
    coords = TextMessage.get_coords(@report.city)
    @report.country = coords[:country]
    @report.lat = coords[:lat]
    @report.lon = coords[:lon]
    climate = TextMessage.get_climate(coords[:lat], coords[:lon])
    @report.temp = climate[:temp]
    @report.prec = climate[:prec]
    @report.identity = request.remote_ip
    @report.destination = "web"
      
    respond_to do |format|
      if @report.save
        format.html { redirect_to @report, notice: 'Report was successfully created.' }
        format.json { render :show, status: :created, location: @report }
      else
        format.html { render :new }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reports/1
  # PATCH/PUT /reports/1.json
  def update
    respond_to do |format|
      if @report.update(report_params)
        format.html { redirect_to @report, notice: 'Report was successfully updated.' }
        format.json { render :show, status: :ok, location: @report }
      else
        format.html { render :edit }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reports/1
  # DELETE /reports/1.json
  def destroy
    @report.destroy
    respond_to do |format|
      format.html { redirect_to reports_url, notice: 'Report was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_report
      @report = Report.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def report_params
      params.require(:report).permit(:value, :crop, :statistic)
    end
end
