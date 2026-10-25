namespace :search do
  desc "検索索引を作り直す（Elasticsearch のときだけ。新しい索引を作ってからエイリアスを付け替える）"
  task reindex: :environment do
    backend = Search.backend
    unless backend.indexes_documents?
      puts "#{backend.class.name} は索引を持たないので何もしません"
      next
    end

    index = backend.reindex_all(Facility.all)
    puts "#{Facility.count} 件を #{index} に索引し、#{backend.index_alias} を付け替えました"
  end
end
