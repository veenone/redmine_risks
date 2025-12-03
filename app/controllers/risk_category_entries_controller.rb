class RiskCategoryEntriesController < ApplicationController
  menu_item :risk_management

  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_category_entry, only: [:edit, :update, :destroy]

  def index
    @categories = @project.risk_category_entries.sorted
  end

  def new
    @category = @project.risk_category_entries.build
  end

  def create
    @category = @project.risk_category_entries.build
    @category.safe_attributes = params[:risk_category_entry]

    if @category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_risk_category_entries_path(@project)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @category.safe_attributes = params[:risk_category_entry]

    if @category.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_category_entries_path(@project)
    else
      render :edit
    end
  end

  def destroy
    if @category.risks.any?
      flash[:error] = l(:error_can_not_delete_category_in_use)
    else
      @category.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to project_risk_category_entries_path(@project)
  end

  private

  def find_category_entry
    @category = @project.risk_category_entries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
