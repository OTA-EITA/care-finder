class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favorites, %i[user_id facility_id], unique: true
  end
end
