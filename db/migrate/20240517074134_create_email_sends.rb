class CreateEmailSends < ActiveRecord::Migration[7.1]
  def change
    create_table :email_sends do |t|
      t.references :post, null: false, foreign_key: true
      t.string :email_id
      t.string :status

      t.timestamps
    end
  end
end
