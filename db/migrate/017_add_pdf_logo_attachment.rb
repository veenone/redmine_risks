class AddPdfLogoAttachment < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_project_settings, :pdf_logo_attachment_id, :integer
    add_index :risk_project_settings, :pdf_logo_attachment_id
  end
end
