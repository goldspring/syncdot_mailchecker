# -*- coding: utf-8 -*-
require 'rubygems'
require 'sqlite3'

class AppData

  def setup
    databaseName  = 'mailchecker.sqlite'
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
    basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory()
    @basePath = basePath.stringByAppendingPathComponent(databaseName)
    fileManager = NSFileManager.defaultManager

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
    query = "select key, data from info;"
    datas = {}
    SQLite3::Database.new(@basePath).execute(query) do |row|
      datas[:"#{row.first}"] = row.second
    end
    datas
  end

  def save(datas)
    setup
    begin
      db = SQLite3::Database.new(@basePath)
      datas.each do |key ,val|
        db.execute("INSERT OR REPLACE INTO info (#{key}) VALUES (?);", val)
      end
    ensure
      db.close
    end
  end
end
