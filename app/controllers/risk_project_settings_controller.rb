class RiskProjectSettingsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  def show
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @impact_point_settings = RiskImpactPointSetting.for_project(@project)
    @probability_point_settings = RiskProbabilityPointSetting.for_project(@project)
  end

  def update
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @risk_project_setting.safe_attributes = params[:risk_project_setting]

    if @risk_project_setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_settings_path(@project)
    else
      @impact_point_settings = RiskImpactPointSetting.for_project(@project)
      @probability_point_settings = RiskProbabilityPointSetting.for_project(@project)
      render :show
    end
  end

  # Initialize default impact/probability point settings for project
  def initialize_point_settings
    RiskImpactPointSetting.create_defaults_for_project(@project)
    RiskProbabilityPointSetting.create_defaults_for_project(@project)
    flash[:notice] = l(:notice_point_settings_initialized)
    redirect_to project_risk_settings_path(@project)
  end

  # Update impact point settings
  def update_impact_points
    if params[:impact_point_settings].present?
      update_point_settings(RiskImpactPointSetting, params[:impact_point_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Update probability point settings
  def update_probability_points
    if params[:probability_point_settings].present?
      update_point_settings(RiskProbabilityPointSetting, params[:probability_point_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Add new impact point setting
  def add_impact_point
    @setting = RiskImpactPointSetting.new(project: @project)
    @setting.safe_attributes = params[:impact_point_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Add new probability point setting
  def add_probability_point
    @setting = RiskProbabilityPointSetting.new(project: @project)
    @setting.safe_attributes = params[:probability_point_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete impact point setting
  def delete_impact_point
    @setting = RiskImpactPointSetting.where(project: @project).find(params[:setting_id])
    if @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_could_not_delete)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete probability point setting
  def delete_probability_point
    @setting = RiskProbabilityPointSetting.where(project: @project).find(params[:setting_id])
    if @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_could_not_delete)
    end
    redirect_to project_risk_settings_path(@project)
  end

  private

  def update_point_settings(model, settings_params)
    settings_params.each do |id, attrs|
      setting = model.where(project: @project).find_by(id: id)
      if setting
        setting.safe_attributes = attrs
        setting.save!
      end
    end
  end
end
