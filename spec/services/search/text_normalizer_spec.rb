require "rails_helper"

RSpec.describe Search::TextNormalizer do
  describe ".normalize" do
    it "全角英数字と記号を半角にそろえ小文字にする" do
      expect(described_class.normalize("ＭＫＡ　Ｓｕｐｐｏｒｔ１２３")).to eq("mka support123")
    end

    it "ひらがなをカタカナにそろえる" do
      expect(described_class.normalize("さくら")).to eq("サクラ")
    end

    it "半角カタカナを全角カタカナにする" do
      expect(described_class.normalize("ｻｸﾗ")).to eq("サクラ")
    end

    it "連続する空白を1つにまとめ前後を取り除く" do
      expect(described_class.normalize("  帯広　 放課後  ")).to eq("帯広 放課後")
    end

    it "nil は空文字にする" do
      expect(described_class.normalize(nil)).to eq("")
    end
  end

  describe ".terms" do
    it "空白で区切った語に分け重複を除く" do
      expect(described_class.terms("運動　療育 運動")).to eq(%w[運動 療育])
    end
  end
end
