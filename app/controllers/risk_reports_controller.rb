class RiskReportsController < ApplicationController
    before_action :find_project_by_project_id, :authorize, :only => [:project_report]
    before_action :require_admin, :only => [:global_report]
    
    helper :risks
    include RisksHelper
    
    def global_report
      # For admin users - report of all projects
      @projects = Project.visible.has_module(:risks).order(:name)
      
      # Get risks statistics for all visible projects
      @total_risks = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      @open_risks = Risk.where(closed_on: nil).joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      @closed_risks = Risk.where.not(closed_on: nil).joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      
      # Risks by probability and impact
      @risks_by_probability = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
                                   .group(:probability).count.transform_keys { |k| k || 0 }
      @risks_by_impact = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
                             .group(:impact).count.transform_keys { |k| k || 0 }
      
      # Risks by status and strategy
      @risks_by_status = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).group(:status).count
      @risks_by_strategy = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).group(:strategy).count
      
      # All risks for report
      @risks = Risk.joins(:project)
                   .where(projects: { status: Project::STATUS_ACTIVE })
                   .includes(:project, :author, :assigned_to, :category)
                   .order('projects.name, risks.id')
      
      respond_to do |format|
        format.html { redirect_to risk_dashboard_path }
        format.xlsx { 
          send_data generate_xlsx_global, 
          filename: "risks_global_report_#{Date.today}.xlsx", 
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
        }
        format.pdf {
          send_data generate_pdf_global,
          filename: "risks_global_report_#{Date.today}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
        }
      end
    end
    
    def project_report
      # Project specific report
      # Use the association if it exists, otherwise use direct Risk query
      if @project.respond_to?(:risks)
        project_risks = @project.risks
      else
        project_risks = Risk.where(project_id: @project.id)
      end
      
      @total_risks = project_risks.count
      @open_risks = project_risks.where(closed_on: nil).count
      @closed_risks = project_risks.where.not(closed_on: nil).count
      
      # Risks by probability and impact
      @risks_by_probability = project_risks.group(:probability).count.transform_keys { |k| k || 0 }
      @risks_by_impact = project_risks.group(:impact).count.transform_keys { |k| k || 0 }
      
      # Risk probability/impact matrix
      @risk_matrix = {}
      
      # Risks by status and strategy
      @risks_by_status = project_risks.group(:status).count
      @risks_by_strategy = project_risks.group(:strategy).count.reject { |k, _| k.nil? }
      
      # All risks for this project
      @risks = project_risks.includes(:author, :assigned_to, :category).order('risks.id')
      
      respond_to do |format|
        format.html { redirect_to project_risk_dashboard_path(@project) }
        format.xlsx { 
          send_data generate_xlsx_project, 
          filename: "risks_#{@project.identifier}_report_#{Date.today}.xlsx", 
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
        }
        format.pdf {
          send_data generate_pdf_project,
          filename: "risks_#{@project.identifier}_report_#{Date.today}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
        }
      end
    end
    
    private
    
    def generate_xlsx_global
      package = Axlsx::Package.new
      workbook = package.workbook
      
      # Summary sheet
      workbook.add_worksheet(name: "Summary") do |sheet|
        # Title
        sheet.add_row ["Global Risk Report - #{Date.today}"], style: workbook.styles.add_style(b: true, sz: 14)
        sheet.add_row []
        
        # Statistics
        sheet.add_row ["Total Risks", @total_risks], style: workbook.styles.add_style(b: true)
        sheet.add_row ["Open Risks", @open_risks]
        sheet.add_row ["Closed Risks", @closed_risks]
        sheet.add_row []
        
        # Risks by Status
        sheet.add_row ["Risks by Status"], style: workbook.styles.add_style(b: true)
        Risk::RISK_STATUS.each do |status|
          sheet.add_row [format_risk_status(status), @risks_by_status[status] || 0]
        end
        sheet.add_row []
        
        # Risks by Strategy
        sheet.add_row ["Risks by Strategy"], style: workbook.styles.add_style(b: true)
        Risk::RISK_STRATEGY.each do |strategy|
          sheet.add_row [format_risk_strategy(strategy), @risks_by_strategy[strategy] || 0]
        end
        sheet.add_row []
        
        # Projects Summary
        sheet.add_row ["Projects with Risks"], style: workbook.styles.add_style(b: true)
        sheet.add_row ["Project", "Total", "Open", "High/Extreme"], style: workbook.styles.add_style(b: true)
        @projects.each do |project|
          # Use direct query approach to be safe
          project_risks = Risk.where(project_id: project.id)
          sheet.add_row [
            project.name, 
            project_risks.count, 
            project_risks.where(closed_on: nil).count, 
            project_risks.where(closed_on: nil).where("probability >= ? AND impact >= ?", 50, 50).count
          ]
        end
      end
      
      # Risks Details sheet
      workbook.add_worksheet(name: "Risk Details") do |sheet|
        # Headers
        headers = [
          "ID", "Project", "Subject", "Status", "Probability", "Impact", "Magnitude", "Strategy", 
          "Category", "Assigned To", "Author", "Created", "Updated"
        ]
        sheet.add_row headers, style: workbook.styles.add_style(b: true, bg_color: "DDDDDD")
        
        # Risks
        @risks.each do |risk|
          sheet.add_row [
            risk.id,
            risk.project.name,
            risk.subject,
            format_risk_status(risk.status),
            risk.probability ? format_risk_probability(risk.probability) : "-",
            risk.impact ? format_risk_impact(risk.impact) : "-",
            risk.magnitude || "-",
            risk.strategy ? format_risk_strategy(risk.strategy) : "-",
            risk.category ? risk.category.name : "-",
            risk.assigned_to ? risk.assigned_to.name : "-",
            risk.author ? risk.author.name : "-",
            format_date(risk.created_on),
            format_date(risk.updated_on)
          ]
        end
      end
      
      package.to_stream.read
    end
    
    def generate_xlsx_project
      package = Axlsx::Package.new
      workbook = package.workbook
      
      # Summary sheet
      workbook.add_worksheet(name: "Summary") do |sheet|
        # Title
        sheet.add_row ["Risk Report - #{@project.name} - #{Date.today}"], style: workbook.styles.add_style(b: true, sz: 14)
        sheet.add_row []
        
        # Statistics
        sheet.add_row ["Total Risks", @total_risks], style: workbook.styles.add_style(b: true)
        sheet.add_row ["Open Risks", @open_risks]
        sheet.add_row ["Closed Risks", @closed_risks]
        sheet.add_row []
        
        # Risks by Status
        sheet.add_row ["Risks by Status"], style: workbook.styles.add_style(b: true)
        Risk::RISK_STATUS.each do |status|
          sheet.add_row [format_risk_status(status), @risks_by_status[status] || 0]
        end
        sheet.add_row []
        
        # Risks by Strategy
        sheet.add_row ["Risks by Strategy"], style: workbook.styles.add_style(b: true)
        Risk::RISK_STRATEGY.each do |strategy|
          sheet.add_row [format_risk_strategy(strategy), @risks_by_strategy[strategy] || 0]
        end
      end
      
      # Risk Matrix sheet
      workbook.add_worksheet(name: "Risk Matrix") do |sheet|
        # Title
        sheet.add_row ["Risk Matrix - #{@project.name}"], style: workbook.styles.add_style(b: true, sz: 14)
        sheet.add_row []
        
        # Matrix headers
        headers = [""]
        Risk::RISK_IMPACT.each_with_index do |impact, index|
          headers << "#{format_risk_impact(index * 25)} (#{index * 25}%)"
        end
        sheet.add_row headers, style: workbook.styles.add_style(b: true)
        
        # Matrix rows
        Risk::RISK_PROBABILITY.reverse.each_with_index do |probability, rev_index|
          index = Risk::RISK_PROBABILITY.size - 1 - rev_index
          row = ["#{format_risk_probability(index * 25)} (#{index * 25}%)"]
          
          Risk::RISK_IMPACT.each_with_index do |impact, i_index|
            p_value = index * 25
            i_value = i_index * 25
            count = @risks.where(probability: p_value, impact: i_value).count
            
            row << count.to_s
          end
          
          sheet.add_row row
        end
      end
      
      # Risks Details sheet
      workbook.add_worksheet(name: "Risk Details") do |sheet|
        # Headers
        headers = [
          "ID", "Subject", "Status", "Probability", "Impact", "Magnitude", "Strategy", 
          "Category", "Assigned To", "Author", "Created", "Updated"
        ]
        sheet.add_row headers, style: workbook.styles.add_style(b: true, bg_color: "DDDDDD")
        
        # Risks
        @risks.each do |risk|
          sheet.add_row [
            risk.id,
            risk.subject,
            format_risk_status(risk.status),
            risk.probability ? format_risk_probability(risk.probability) : "-",
            risk.impact ? format_risk_impact(risk.impact) : "-",
            risk.magnitude || "-",
            risk.strategy ? format_risk_strategy(risk.strategy) : "-",
            risk.category ? risk.category.name : "-",
            risk.assigned_to ? risk.assigned_to.name : "-",
            risk.author ? risk.author.name : "-",
            format_date(risk.created_on),
            format_date(risk.updated_on)
          ]
        end
      end
      
      # Treatments and Lessons sheets
      workbook.add_worksheet(name: "Treatments & Lessons") do |sheet|
        # Headers
        sheet.add_row ["ID", "Subject", "Treatments", "Lessons Learned"], style: workbook.styles.add_style(b: true, bg_color: "DDDDDD")
        
        # Risks with treatments or lessons
        @risks.each do |risk|
          if risk.treatments? || risk.lessons?
            sheet.add_row [
              risk.id,
              risk.subject,
              strip_html(risk.treatments.to_s),
              strip_html(risk.lessons.to_s)
            ]
          end
        end
      end
      
      package.to_stream.read
    end
    
    def generate_pdf_global
      pdf = Prawn::Document.new(:page_size => "A4", :margin => [30, 30, 30, 30])
      
      # Title
      pdf.font_size(20) { pdf.text "Global Risk Report", :style => :bold }
      pdf.font_size(12) { pdf.text "Generated on #{format_date(Date.today)}" }
      pdf.move_down 20
      
      # Summary
      pdf.font_size(16) { pdf.text "Summary", :style => :bold }
      pdf.move_down 5
      
      summary_data = [
        ["Total Risks:", @total_risks.to_s],
        ["Open Risks:", @open_risks.to_s],
        ["Closed Risks:", @closed_risks.to_s]
      ]
      
      pdf.table(summary_data, :width => 200) do
        cells.borders = []
        column(0).font_style = :bold
        column(0).width = 120
      end
      
      pdf.move_down 20
      
      # Projects Summary
      pdf.font_size(16) { pdf.text "Projects with Risks", :style => :bold }
      pdf.move_down 5
      
      projects_data = [["Project", "Total", "Open", "High/Extreme"]]
      @projects.each do |project|
        # Use direct query approach to be safe
        project_risks = Risk.where(project_id: project.id)
        projects_data << [
          project.name, 
          project_risks.count.to_s, 
          project_risks.where(closed_on: nil).count.to_s, 
          project_risks.where(closed_on: nil).where("probability >= ? AND impact >= ?", 50, 50).count.to_s
        ]
      end
      
      pdf.table(projects_data, :header => true, :width => pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "DDDDDD"
      end
      
      pdf.move_down 20
      
      # Top Risks
      pdf.font_size(16) { pdf.text "Top Risks", :style => :bold }
      pdf.move_down 5
      
      require 'arel'
      top_risks = Risk.joins(:project)
                      .where(projects: { status: Project::STATUS_ACTIVE })
                      .where(closed_on: nil)
                      .where.not(probability: nil)
                      .where.not(impact: nil)
                      .order(Arel.sql('probability * impact DESC'))
                      .limit(10)
                      .includes(:project)
      
      top_risks_data = [["ID", "Project", "Subject", "Magnitude"]]
      top_risks.each do |risk|
        top_risks_data << [
          risk.id.to_s, 
          risk.project.name, 
          risk.subject,
          risk.magnitude.to_s
        ]
      end
      
      pdf.table(top_risks_data, :header => true, :width => pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "DDDDDD"
        column(2).width = 250
      end
      
      # Footer with page numbers
      pdf.number_pages "Page <page> of <total>", :at => [pdf.bounds.right - 150, 0]
      
      pdf.render
    end
    
    def generate_pdf_project
      pdf = Prawn::Document.new(:page_size => "A4", :margin => [30, 30, 30, 30])
      
      # Title
      pdf.font_size(20) { pdf.text "#{@project.name}: Risk Report", :style => :bold }
      pdf.font_size(12) { pdf.text "Generated on #{format_date(Date.today)}" }
      pdf.move_down 20
      
      # Summary
      pdf.font_size(16) { pdf.text "Summary", :style => :bold }
      pdf.move_down 5
      
      summary_data = [
        ["Total Risks:", @total_risks.to_s],
        ["Open Risks:", @open_risks.to_s],
        ["Closed Risks:", @closed_risks.to_s]
      ]
      
      pdf.table(summary_data, :width => 200) do
        cells.borders = []
        column(0).font_style = :bold
        column(0).width = 120
      end
      
      pdf.move_down 20
      
      # Top Risks
      pdf.font_size(16) { pdf.text "Top Risks by Magnitude", :style => :bold }
      pdf.move_down 5
      
      require 'arel'
      top_risks = @risks.where(closed_on: nil)
                         .where.not(probability: nil)
                         .where.not(impact: nil)
                         .order(Arel.sql('probability * impact DESC'))
                         .limit(10)
      
      if top_risks.any?
        top_risks_data = [["ID", "Subject", "Probability", "Impact", "Magnitude"]]
        top_risks.each do |risk|
          top_risks_data << [
            risk.id.to_s, 
            risk.subject,
            risk.probability ? format_risk_probability(risk.probability) : "-",
            risk.impact ? format_risk_impact(risk.impact) : "-",
            risk.magnitude.to_s
          ]
        end
        
        pdf.table(top_risks_data, :header => true, :width => pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "DDDDDD"
          column(1).width = 200
        end
      else
        pdf.text "No risks with magnitude data available."
      end
      
      pdf.move_down 20
      
      # Risk list
      pdf.font_size(16) { pdf.text "Risk List", :style => :bold }
      pdf.move_down 5
      
      risk_data = [["ID", "Subject", "Status", "Assigned To", "Magnitude"]]
      @risks.each do |risk|
        risk_data << [
          risk.id.to_s,
          risk.subject,
          format_risk_status(risk.status),
          risk.assigned_to ? risk.assigned_to.name : "-",
          risk.magnitude || "-"
        ]
      end
      
      pdf.table(risk_data, :header => true, :width => pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "DDDDDD"
        column(1).width = 200
      end
      
      # New page for detailed risks
      pdf.start_new_page
      
      pdf.font_size(16) { pdf.text "Risk Details", :style => :bold }
      pdf.move_down 10
      
      # Detailed information about each risk
      @risks.each_with_index do |risk, index|
        if index > 0
          pdf.move_down 15
          pdf.stroke_horizontal_rule
          pdf.move_down 15
        end
        
        pdf.font_size(14) { pdf.text "Risk ##{risk.id}: #{risk.subject}", :style => :bold }
        pdf.move_down 5
        
        details = [
          ["Status:", format_risk_status(risk.status)],
          ["Category:", risk.category ? risk.category.name : "-"],
          ["Probability:", risk.probability ? format_risk_probability(risk.probability) : "-"],
          ["Impact:", risk.impact ? format_risk_impact(risk.impact) : "-"],
          ["Magnitude:", risk.magnitude || "-"],
          ["Strategy:", risk.strategy ? format_risk_strategy(risk.strategy) : "-"],
          ["Assigned to:", risk.assigned_to ? risk.assigned_to.name : "-"],
          ["Created by:", risk.author ? risk.author.name : "-"],
          ["Created on:", format_date(risk.created_on)],
          ["Updated on:", format_date(risk.updated_on)]
        ]
        
        pdf.table(details, :width => 400) do
          cells.borders = []
          column(0).font_style = :bold
          column(0).width = 100
        end
        
        if risk.description?
          pdf.move_down 10
          pdf.font_size(11) { pdf.text "Description:", :style => :bold }
          pdf.text strip_html(risk.description.to_s)
        end
        
        if risk.treatments?
          pdf.move_down 10
          pdf.font_size(11) { pdf.text "Treatments:", :style => :bold }
          pdf.text strip_html(risk.treatments.to_s)
        end
        
        if risk.lessons?
          pdf.move_down 10
          pdf.font_size(11) { pdf.text "Lessons Learned:", :style => :bold }
          pdf.text strip_html(risk.lessons.to_s)
        end
        
        # Add a page break if this risk entry would go across multiple pages
        if index < @risks.size - 1 && pdf.cursor < 150
          pdf.start_new_page
        end
      end
      
      # Footer with page numbers
      pdf.number_pages "Page <page> of <total>", :at => [pdf.bounds.right - 150, 0]
      
      pdf.render
    end
    
    def strip_html(text)
      text.gsub(/<\/?[^>]*>/, "").gsub(/&nbsp;/, " ")
    end
  end