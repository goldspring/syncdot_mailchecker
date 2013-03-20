# -*- coding: japanese-cp932 -*-
#
#  prefs.rb
#  mailchecker
#
#  Created by cross on 2013/03/20.
#  Copyright 2013年 crossagate. All rights reserved.
#
require 'uri'
require 'json'
require 'macruby_http'
require 'data'

class Prefs
  include MacRubyHelper::DownloadHelper
  attr_accessor :server
  attr_accessor :port
  attr_accessor :user
  attr_accessor :pass
  attr_accessor :interval

  def start
    if @timer
      @timer.invalidate
      @timer = nil
    end
    @timer = NSTimer
      .scheduledTimerWithTimeInterval(interval.to_i * 60,
                                      target: self,
                                      selector: "timerHandler:",
                                      userInfo: nil,
                                      repeats: true)
    mailcheck
  end

  def timerHandler(obj)
    mailcheck
  end

  def mailcheck
    name, domain = user.split("@",2)
    url = "https://#{server}:#{port}/webmail/rest/Message/#{domain}/#{name}?unseen=1"
    puts url
    download url do |mr|
      # The response object has 3 accessors: status_code, headers and body
      NSLog("status: #{mr.status_code}, Headers: #{mr.headers.inspect}")
      err = Pointer.new('@');
      jsonArray = NSJSONSerialization.JSONObjectWithData(mr.body, options:NSJSONReadingAllowFragments, error:err)
      if err[0]
        puts err[0].description
        raise
      else
        status_bar = NSStatusBar.systemStatusBar
        status_item = status_bar.statusItemWithLength(NSVariableStatusItemLength)
        status_item.setTitle(jsonArray.size)
      end
    end
  end
end
