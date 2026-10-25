module Search
  # 検索語と索引の両方に同じ正規化をかけて、表記ゆれで取りこぼさないようにする。
  #   - NFKC で全角英数字・半角カナ・全角スペースをそろえる
  #   - ひらがなをカタカナに寄せる（「さくら」でも「サクラ」でも当たる）
  #   - 英字は小文字にする
  module TextNormalizer
    HIRAGANA = "ぁ-ゖ".freeze
    KATAKANA = "ァ-ヶ".freeze

    module_function

    def normalize(text)
      return "" if text.nil?

      text.to_s
        .unicode_normalize(:nfkc)
        .tr(HIRAGANA, KATAKANA)
        .downcase
        .gsub(/[[:space:]]+/, " ")
        .strip
    end

    def terms(text)
      normalize(text).split(" ").uniq
    end
  end
end
