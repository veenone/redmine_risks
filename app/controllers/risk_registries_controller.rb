class RiskRegistriesController < ApplicationController
  menu_item :risk_management

  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_registry, only: [:edit, :update, :destroy]

  def index
    @registries = @project.risk_registries.includes(:risk_category_entry).sorted
  end

  def new
    @registry = @project.risk_registries.build
  end

  def create
    @registry = @project.risk_registries.build
    @registry.safe_attributes = params[:risk_registry]

    if @registry.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_risk_registries_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @registry.safe_attributes = params[:risk_registry]

    if @registry.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_registries_path(@project)
    else
      render :edit
    end
  end

  def destroy
    if @registry.risks.any?
      flash[:error] = l(:error_can_not_delete_registry_in_use)
    else
      @registry.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to project_risk_registries_path(@project)
  end

  private

  def find_registry
    @registry = @project.risk_registries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
