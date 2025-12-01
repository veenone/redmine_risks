class RiskImportsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  def new
    @import = RiskImport.new
  end

  def create
    @import = RiskImport.new(project: @project, user: User.current)

    if params[:file].blank?
      flash[:error] = l(:error_no_file_selected)
      render :new
      return
    end

    file = params[:file]
    unless file.original_filename.end_with?('.csv')
      flash[:error] = l(:error_invalid_file_format)
      render :new
      return
    end

    begin
      @import.parse_file(file)

      if @import.errors.any?
        flash.now[:error] = l(:error_import_failed)
        render :new
      else
        flash[:notice] = l(:notice_risk_import_successful, count: @import.imported_count)
        redirect_to project_risks_path(@project)
      end
    rescue => e
      Rails.logger.error "Risk import error: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:error] = l(:error_import_failed) + ": #{e.message}"
      render :new
    end
  end

  def template
    send_data generate_csv_template,
              filename: "risk_import_template.csv",
              type: "text/csv; charset=utf-8"
  end

  private

  def generate_csv_template
    require 'csv'

    headers = [
      'No.', 'Category', 'Risk', 'Threat Event', 'Risk Id', 'Areas/Assets',
      'Risk Owner', 'Impacted Assets', 'Vulnerabilities', 'Consequences',
      'Counter-Measures', 'C', 'I', 'A', 'Impact', 'Probability',
      'Level of Significance', 'Risk Treatment', 'Risk Treatment Owner',
      'Mitigation', 'Prevention', 'Target Date', 'Completion Date', 'Remark'
    ]

    CSV.generate(headers: true) do |csv|
      csv << headers
      # Example row
      csv << [
        '1', 'Natural', 'Fire', 'Fire Disruption', 'N001001', 'General Offices',
        'Building Facility PIC', 'Infrastructure', 'Flammable materials',
        'Fire damage to building', 'Fire extinguishers installed',
        'N', 'Y', 'Y', '3', '1', '3', 'Risk Transfer', 'Facility Manager',
        'Fire training', 'Sprinkler installation', '', '', 'Sample risk entry'
      ]
    end
  end
end
