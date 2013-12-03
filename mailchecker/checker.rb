#
#  checker.rb
#  mailchecker
#
#  Created by  on 2013/03/20.
#
require 'uri'
require 'json'
require 'macruby_http'
require 'data'

class Checker
  include MacRubyHelper::DownloadHelper
  attr_accessor :observer

  attr_accessor :server
  attr_accessor :port
  attr_accessor :user
  attr_accessor :pass
  attr_accessor :interval
  attr_accessor :stop_checking

  def start
    if @timer
      @timer.invalidate
      @timer = nil
    end
    if interval.to_i > 0
      @timer = NSTimer
        .scheduledTimerWithTimeInterval(interval.to_i * 60,
                                        target: self,
                                        selector: "timerHandler:",
                                        userInfo: nil,
                                        repeats: true)
      mailcheck
    end
  end

  def timerHandler(obj)
    mailcheck
  end

  def mailcheck
    return if @stop_checking
    name, domain = user.split("@",2)
    url = "https://#{server}/webmail/rest/Message/#{domain}/#{name}?unseen=1&folder=INBOX/**&folder=NORMAL/**"
    puts url
    download(url, {:credential => {:user => user, :password => pass}}) do |mr|
      # The response object has 3 accessors: status_code, headers and body
      NSLog("status: #{mr.status_code}, Headers: #{mr.headers.inspect}")
      err = Pointer.new('@');
      jsonArray = NSJSONSerialization.JSONObjectWithData(mr.body, options:NSJSONReadingAllowFragments, error:err)
      if err[0]
        puts err[0].description
        raise
      else
        @observer.findedUnseen(jsonArray)
      end
    end
  end
end
