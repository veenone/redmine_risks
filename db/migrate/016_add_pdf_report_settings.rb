class AddPdfReportSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_project_settings, :pdf_logo_path, :string
    add_column :risk_project_settings, :pdf_product_name, :string
    add_column :risk_project_settings, :pdf_show_generated_time, :boolean, default: true
    add_column :risk_project_settings, :pdf_show_logo, :boolean, default: false
    add_column :risk_project_settings, :pdf_show_product_name, :boolean, default: false
  end
end
