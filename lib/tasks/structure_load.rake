# MySQL 9.x のクライアントは --commands を付けないと SOURCE などのクライアントコマンドを実行しない。
# structure.sql の読み込みは SOURCE を使うので、9.x のときだけフラグを足す（CI の 8.0 クライアントは未対応の引数になる）。
if defined?(ActiveRecord::Tasks::DatabaseTasks)
  client_major = `mysql --version 2>/dev/null`[/Ver (\d+)\./, 1].to_i
  ActiveRecord::Tasks::DatabaseTasks.structure_load_flags = [ "--commands" ] if client_major >= 9
end
