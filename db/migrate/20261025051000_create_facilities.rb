class CreateFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :facilities do |t|
      # どこから来たデータか。wamnet = 障害福祉サービス等情報公表システムのオープンデータ、sample = 架空のサンプル
      t.string :source, null: false
      t.string :source_record_no, null: false
      t.date :data_as_of
      t.string :office_number, limit: 10

      t.integer :service_type, null: false
      t.string :name, null: false
      t.string :name_kana
      t.string :corporation_name

      t.string :prefecture, null: false
      t.string :municipality, null: false
      t.string :address_line
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7

      t.string :phone
      t.string :website_url
      t.integer :capacity

      t.string :hours_weekday
      t.string :hours_saturday
      t.string :hours_sunday
      t.string :hours_holiday
      t.boolean :open_weekday, null: false, default: false
      t.boolean :open_saturday, null: false, default: false
      t.boolean :open_sunday, null: false, default: false
      t.boolean :open_holiday, null: false, default: false
      t.text :closed_days
      t.text :availability_notes

      # 以下は事業所の職員が管理画面で入力する項目。オープンデータの再取り込みでは上書きしない
      t.boolean :pickup_available
      t.text :description

      # 検索用に正規化したテキスト（Search::TextNormalizer）
      t.text :search_text

      t.timestamps
    end

    add_index :facilities, %i[source source_record_no], unique: true
    add_index :facilities, :office_number
    add_index :facilities, %i[prefecture municipality]
    add_index :facilities, :service_type

    # 日本語は分かち書きがないので ngram パーサーで 2-gram に分割して索引を作る
    reversible do |dir|
      dir.up { execute "CREATE FULLTEXT INDEX index_facilities_on_search_text ON facilities (search_text) WITH PARSER ngram" }
      dir.down { remove_index :facilities, name: "index_facilities_on_search_text" }
    end
  end
end
