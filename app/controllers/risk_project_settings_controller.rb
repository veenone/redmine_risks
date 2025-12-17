class RiskProjectSettingsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  def show
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @impact_point_settings = RiskImpactPointSetting.for_project(@project)
    @probability_point_settings = RiskProbabilityPointSetting.for_project(@project)
    @strategy_settings = RiskStrategySetting.for_project(@project)
    @probability_entry_settings = RiskProbabilityEntrySetting.for_project(@project)
    @impact_entry_settings = RiskImpactEntrySetting.for_project(@project)
    @treatment_plan_settings = RiskTreatmentPlanSetting.for_project(@project)
    @vulnerability_entries = RiskVulnerabilityEntry.for_project(@project)
    @consequence_entries = RiskConsequenceEntry.for_project(@project)
    @counter_measure_entries = RiskCounterMeasureEntry.for_project(@project)
  end

  def update
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @risk_project_setting.safe_attributes = params[:risk_project_setting]

    # Handle logo file upload
    if params[:pdf_logo_file].present?
      @risk_project_setting.pdf_logo_file = params[:pdf_logo_file]
    end

    if @risk_project_setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_settings_path(@project)
    else
      @impact_point_settings = RiskImpactPointSetting.for_project(@project)
      @probability_point_settings = RiskProbabilityPointSetting.for_project(@project)
      render :show
    end
  end

  # Delete uploaded logo
  def delete_logo
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @risk_project_setting.delete_pdf_logo
    flash[:notice] = l(:notice_logo_deleted)
    redirect_to project_risk_settings_path(@project)
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

  # Initialize strategy settings
  def initialize_strategy_settings
    RiskStrategySetting.create_defaults_for_project(@project)
    flash[:notice] = l(:notice_settings_initialized)
    redirect_to project_risk_settings_path(@project)
  end

  # Update strategy settings
  def update_strategy_settings
    if params[:strategy_settings].present?
      update_generic_settings(RiskStrategySetting, params[:strategy_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Add strategy setting
  def add_strategy_setting
    @setting = RiskStrategySetting.new(project: @project)
    @setting.safe_attributes = params[:strategy_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete strategy setting
  def delete_strategy_setting
    @setting = RiskStrategySetting.where(project: @project).find(params[:setting_id])
    if @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_could_not_delete)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Initialize probability entry settings
  def initialize_probability_entry_settings
    RiskProbabilityEntrySetting.create_defaults_for_project(@project)
    flash[:notice] = l(:notice_settings_initialized)
    redirect_to project_risk_settings_path(@project)
  end

  # Update probability entry settings
  def update_probability_entry_settings
    if params[:probability_entry_settings].present?
      update_generic_settings(RiskProbabilityEntrySetting, params[:probability_entry_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Add probability entry setting
  def add_probability_entry_setting
    @setting = RiskProbabilityEntrySetting.new(project: @project)
    @setting.safe_attributes = params[:probability_entry_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete probability entry setting
  def delete_probability_entry_setting
    @setting = RiskProbabilityEntrySetting.where(project: @project).find(params[:setting_id])
    if @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_could_not_delete)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Initialize impact entry settings
  def initialize_impact_entry_settings
    RiskImpactEntrySetting.create_defaults_for_project(@project)
    flash[:notice] = l(:notice_settings_initialized)
    redirect_to project_risk_settings_path(@project)
  end

  # Update impact entry settings
  def update_impact_entry_settings
    if params[:impact_entry_settings].present?
      update_generic_settings(RiskImpactEntrySetting, params[:impact_entry_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Add impact entry setting
  def add_impact_entry_setting
    @setting = RiskImpactEntrySetting.new(project: @project)
    @setting.safe_attributes = params[:impact_entry_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete impact entry setting
  def delete_impact_entry_setting
    @setting = RiskImpactEntrySetting.where(project: @project).find(params[:setting_id])
    if @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_could_not_delete)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Initialize treatment plan settings
  def initialize_treatment_plan_settings
    RiskTreatmentPlanSetting.create_defaults_for_project(@project)
    flash[:notice] = l(:notice_settings_initialized)
    redirect_to project_risk_settings_path(@project)
  end

  # Update treatment plan settings
  def update_treatment_plan_settings
    if params[:treatment_plan_settings].present?
      update_generic_settings(RiskTreatmentPlanSetting, params[:treatment_plan_settings])
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_risk_settings_path(@project)
  rescue => e
    flash[:error] = e.message
    redirect_to project_risk_settings_path(@project)
  end

  # Add treatment plan setting
  def add_treatment_plan_setting
    @setting = RiskTreatmentPlanSetting.new(project: @project)
    @setting.safe_attributes = params[:treatment_plan_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @setting.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete treatment plan setting
  def delete_treatment_plan_setting
    @setting = RiskTreatmentPlanSetting.where(project: @project).find(params[:setting_id])
    if @setting.deletable?
      @setting.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_setting_in_use)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Add vulnerability entry
  def add_vulnerability_entry
    @entry = RiskVulnerabilityEntry.new(project: @project)
    @entry.safe_attributes = params[:vulnerability_entry]
    if @entry.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @entry.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete vulnerability entry
  def delete_vulnerability_entry
    @entry = RiskVulnerabilityEntry.where(project: @project).find(params[:entry_id])
    if @entry.deletable?
      @entry.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_entry_in_use)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Add consequence entry
  def add_consequence_entry
    @entry = RiskConsequenceEntry.new(project: @project)
    @entry.safe_attributes = params[:consequence_entry]
    if @entry.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @entry.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete consequence entry
  def delete_consequence_entry
    @entry = RiskConsequenceEntry.where(project: @project).find(params[:entry_id])
    if @entry.deletable?
      @entry.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_entry_in_use)
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Add counter-measure entry
  def add_counter_measure_entry
    @entry = RiskCounterMeasureEntry.new(project: @project)
    @entry.safe_attributes = params[:counter_measure_entry]
    if @entry.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = @entry.errors.full_messages.join(', ')
    end
    redirect_to project_risk_settings_path(@project)
  end

  # Delete counter-measure entry
  def delete_counter_measure_entry
    @entry = RiskCounterMeasureEntry.where(project: @project).find(params[:entry_id])
    if @entry.deletable?
      @entry.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_entry_in_use)
    end
    redirect_to project_risk_settings_path(@project)
  end

  private

  def update_generic_settings(model, settings_params)
    settings_params.each do |id, attrs|
      setting = model.where(project: @project).find_by(id: id)
      if setting
        setting.safe_attributes = attrs
        setting.save!
      end
    end
  end

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
