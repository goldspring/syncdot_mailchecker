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
