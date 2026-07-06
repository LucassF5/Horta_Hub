class CreateImportBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :import_batches do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :status, null: false, default: "pending"
      t.integer :year, null: false
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :successful_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0

      t.json :error_details, null: false, default: []

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
