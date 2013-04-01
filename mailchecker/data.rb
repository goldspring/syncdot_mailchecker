# -*- coding: utf-8 -*-
require 'rubygems'
require 'sqlite3'

class AppData

  def setup
    databaseName  = 'mailchecker.sqlite'
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory()
    fileManager = NSFileManager.defaultManager
    error = Pointer.new('@');
    basePath = basePath.stringByAppendingPathComponent('SyncdotMailChecker')
    fileManager.createDirectoryAtPath(basePath, withIntermediateDirectories:true, attributes:nil, error:error)
    if error[0]
      NSLog(error[0].description);
      raise
    end
    @basePath = basePath.stringByAppendingPathComponent(databaseName)
    # 文章フォルダにデータベースファイルが存在しているかを確認する
    if !fileManager.fileExistsAtPath(@basePath)
      defaultDBPath = NSBundle.mainBundle.resourcePath.stringByAppendingPathComponent(databaseName)
      error = Pointer.new('@');
      # 文章フォルダに存在しない場合は、データベースをコピーする
      success = fileManager.copyItemAtPath(defaultDBPath, toPath:@basePath, error:error)
      if error[0]
        NSLog(error[0].description);
        raise
      else
        NSLog('Database file copied.');
      end
    else

      NSLog('Database file exist.')
    end
  end

  def infos
    setup
    puts @basePath
    datas = {}
    query = "select key, data from infos;"
    SQLite3::Database.new(@basePath).execute(query) do |row|
      datas[:"#{row.first}"] = row[1]
    end
    datas
  end

  def already_reports
    setup
    records = []
    query = "select id, subject, timestamp from unseen;"
    SQLite3::Database.new(@basePath).execute(query) do |row|
      datas = {}
      datas[:id] = row[0]
      datas[:subject] = row[1]
      datas[:timestamp] = row[2]
      records << datas
    end
    records
  end

  def add_already_reports(msgs)
    msgs.each do | msg |
      query = "insert into unseen(id,subject,timestamp) values (?,?,?);"
      stmt = SQLite3::Database.new(@basePath).prepare(query)
      stmt.bind_params(msg[:id].to_i, msg[:subject].to_s, msg[:timestamp].to_s)
      stmt.execute!
    end
  end

  def save(datas)
    setup
    begin
      puts @basePath
      db = SQLite3::Database.new(@basePath)
      datas.each do |key ,val|
        db.execute("INSERT OR REPLACE INTO infos (key,data) VALUES (?, ?);", key.to_s, val.to_s)
      end
    ensure
      db.close
    end
  end
end
