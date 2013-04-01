# -*- coding: utf-8 -*-
#
#  AppDelegate.rb
#  StatusBarSample
#
#  Created by Tokuhiro Matsuno on 1/4/13.
#  Copyright 2013 Tokuhiro Matsuno. All rights reserved.
#
require "checker.rb"

class MenuHelper
  attr_reader :menu

  def self.create(title, &block)
    obj = self.new(title)
    obj.instance_eval &block
    return obj.menu
  end

  def initialize(title)
    @menu = NSMenu.new()
    @menu.initWithTitle('FooApp')
    @menu.autoenablesItems = false
  end

  def item(title, &block)
    item = NSMenuItem.new()
    item.title  = title

    # Create anonnymous class to receive event.
    receiver = Class.new()
    receiver.class_eval do
      define_method(:call) do |sender|
        block.(sender)
      end
    end
    item.action = 'call:'
    item.target = receiver.new

    @menu.addItem item

    return item
  end

  def nest(title, &block)
    item = NSMenuItem.new()
    item.title  = title

    submenu = MenuHelper.new(title)
    item.submenu = submenu.menu
    submenu.instance_eval &block

    @menu.addItem item
  end

  def separator
    @menu.addItem NSMenuItem.separatorItem
  end
end

class AppDelegate
  attr_accessor :window
  attr_accessor :server
  attr_accessor :port
  attr_accessor :user
  attr_accessor :pass
  attr_accessor :interval
  attr_accessor :checker

  def ok_button(sender)
    @checker.tap do |pr|
      pr.server = server.stringValue()
      pr.port = port.integerValue()
      pr.user = user.stringValue()
      pr.pass = pass.stringValue()
      pr.interval = interval.integerValue()
      AppData.new.save({server: pr.server, port: pr.port, user: pr.user, pass: pr.pass, interval: pr.interval})
      pr.observer = self
      pr.start
    end
    window.close
  end

  def findedUnseen(response)
    @status_item.title = "#{response['total']}"
    img = ""
    if "#{response['total']}".to_i > 0
      img = NSImage.imageNamed 'unseen.png'
      find_report(response)
    else
      img = NSImage.imageNamed 'mail.png'
    end
    @status_item.setImage(img)
  end

  def unchecks(response)
    appData = AppData.new
    already_reports = appData.already_reports
    ids = already_reports.map { |r| r[:id] }
    reports = []
    response['message'].each do |msg|
      reports << msg unless ids.include?(msg['id'])
    end
    appData.add_already_reports(reports)
    reports
  end

  def find_report(response)
    unchecks(response).each do |msg|
      notify = NSUserNotification.alloc.init
      notify.title = 'find new mail'
      notify.informativeText = msg['subject']
          NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(notify)
        # NSUserNotificationCenter.defaultUserNotificationCenter.scheduleNotification(notify)
      sleep 3
    end
  end

  def cancel_button(sender)
    window.close
  end

  def startMailCheck
    datas = AppData.new.infos
    if datas[:server] && datas[:port] && datas[:user] && datas[:pass] && datas[:interval]
      @checker.tap do |pr|
        pr.server = datas[:server]
        pr.port = datas[:port]
        pr.user = datas[:user]
        pr.pass = datas[:pass]
        pr.interval = datas[:interval]
        pr.observer = self
        pr.start
      end
    end
  end

  def userNotificationCenter(center, didActivateNotification:notification)
      # アクションボタンがクリックされたら、スケジュールのページを開く
      #    NSURL *url = [NSURL URLWithString:[notification.userInfo valueForKey:@"url"]];
      # NSWorkspace sharedWorkspace] openURL:url];
    datas = AppData.new.infos
    url = NSURL.URLWithString("https://#{datas[:server]}:#{datas[:port]}/webmail/");
    if !NSWorkspace.sharedWorkspace.openURL(url)
      puts("Failed to open url: #{url.description}");
    end
  end

  def setupMenu
    prefwindow = window
    cons = { server: server,  port: port,  user: user,  pass: pass,  interval: interval }
    checker = @checker
    MenuHelper.create("FooApp") do
#      item 'NSAlertMenu' do |sender|
#        alert = NSAlert.new
#        alert.messageText = 'This is MacRuby Status Bar Application'
#        alert.informativeText = 'Cool, huh?'
#        alert.alertStyle = NSInformationalAlertStyle
#        alert.addButtonWithTitle("Yeah!")
#        response = alert.runModal
#      end

      item 'Preferences' do |sender|
        datas = AppData.new.infos
        cons[:server].setStringValue(datas[:server]) if datas[:server]
        cons[:port].setIntegerValue(datas[:port]) if datas[:port]
        cons[:user].setStringValue(datas[:user]) if datas[:user]
        cons[:pass].setStringValue(datas[:pass]) if datas[:pass]
        cons[:interval].setIntegerValue(datas[:interval]) if datas[:interval]

        prefwindow.makeKeyAndOrderFront(sender)
        prefwindow.orderFrontRegardless
        #numberFormatter = NSNumberFormatter.new
        #newAttributes = NSMutableDictionary.dictionary
        #numberFormatter.setFormat("###,##0;(###,##0)")
        #                [newAttributes setObject(NSColor.redColor, forKey:@"NSColor"];
        #                [numberFormatter setTextAttributesForNegativeValues: newAttributes];
        #port.cell.setFormatter(numberFormatter)
      end

      item 'Stop Checking' do |sender|
        unless checker.stop_checking
          sender.setState(NSOnState)
          checker.stop_checking = true
        else
          sender.setState(NSOffState);
          checker.stop_checking = false
        end
      end
#      item 'Open URL' do |sender|
#        url = NSURL.URLWithString("http://www.stackoverflow.com/");
#        if !NSWorkspace.sharedWorkspace.openURL(url)
#          puts("Failed to open url: #{url.description}");
#        end
#      end
#
#      nest 'Project' do
#        task1 = item 'Task1' do |sender|
#          puts "Task1"
#          p sender
#        end
#        item 'Task2' do |sender|
#          task1.enabled = !task1.isEnabled
#        end
#        nest 'Task3' do
#          item 'Subtask 1' do
#            puts "Task3/Subtask 1"
#          end
#        end
#      end
#
#      item 'Notification Center' do |sender|
#        notify = NSUserNotification.alloc.init
#        notify.title = 'Title of notification'
#        notify.informativeText = 'Body of notification'
#        NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(notify)
#      end

      separator

      item 'Quit' do |sender|
        app = NSApplication.sharedApplication
        app.terminate(self)
      end
    end
  end

  def initStatusBar(menu)
    status_bar = NSStatusBar.systemStatusBar
    @status_item = status_bar.statusItemWithLength(NSVariableStatusItemLength)
    @status_item.setMenu menu
    img = NSImage.imageNamed 'mail.png'
    @status_item.setImage(img)
    @status_item.title = ""
    @status_item.highlightMode = true
  end

  def applicationDidFinishLaunching(a_notification)
    app = NSApplication.sharedApplication

    @checker = Checker.new
    NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
    initStatusBar(setupMenu())
    startMailCheck
    app.run
  end
end
