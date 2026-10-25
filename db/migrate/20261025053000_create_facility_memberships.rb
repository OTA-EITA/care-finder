# どのユーザーがどの事業所の掲載情報を編集できるか
class CreateFacilityMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :facility_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.timestamps
    end
    add_index :facility_memberships, %i[user_id facility_id], unique: true
  end
end
