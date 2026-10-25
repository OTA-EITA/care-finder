# 支援内容のタグ（運動療育、学習支援など）。事業所の職員が管理画面で選ぶ
class CreateFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :features do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :features, :code, unique: true

    create_table :facility_features do |t|
      t.references :facility, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.timestamps
    end
    add_index :facility_features, %i[facility_id feature_id], unique: true
  end
end
