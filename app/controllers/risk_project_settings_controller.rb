class RiskProjectSettingsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  def show
    @risk_project_setting = RiskProjectSetting.for_project(@project)
  end

  def update
    @risk_project_setting = RiskProjectSetting.for_project(@project)
    @risk_project_setting.safe_attributes = params[:risk_project_setting]

    if @risk_project_setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_risk_settings_path(@project)
    else
      render :show
    end
  end
end
