class RiskAreasController < ApplicationController
  menu_item :risk_management

  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_area, only: [:edit, :update, :destroy]

  def index
    @areas = @project.risk_areas.sorted
  end

  def new
    @area = @project.risk_areas.build
  end

  def create
    @area = @project.risk_areas.build
    @area.safe_attributes = params[:risk_area]

    if @area.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_risk_areas_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @area.safe_attributes = params[:risk_area]

    if @area.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_areas_path(@project)
    else
      render :edit
    end
  end

  def destroy
    if @area.risks.any?
      flash[:error] = l(:error_can_not_delete_area_in_use)
    else
      @area.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to project_risk_areas_path(@project)
  end

  private

  def find_area
    @area = @project.risk_areas.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
