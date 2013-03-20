#
#  AppDelegate.rb
#  StatusBarSample
#
#  Created by Tokuhiro Matsuno on 1/4/13.
#  Copyright 2013 Tokuhiro Matsuno. All rights reserved.
#
require "prefs.rb"

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

    def ok_button(sender)

      @prefs ||=  Prefs.new
      @prefs.tap do |pr|
        pr.server = server.stringValue()
        pr.port = port.integerValue()
        pr.user = user.stringValue()
        pr.pass = pass.stringValue()
        pr.interval = interval.integerValue()
        AppData.new.save({server: pr.server, port: pr.port, user: pr.user, pass: pr.pass, interval: pr.interval})
        pr.start
      end
      window.close
    end

    def cancel_button(sender)
        window.close
    end

    def setupMenu
        prefwindow = window
        MenuHelper.create("FooApp") do
            item 'NSAlertMenu' do |sender|
                alert = NSAlert.new
                alert.messageText = 'This is MacRuby Status Bar Application'
                alert.informativeText = 'Cool, huh?'
                alert.alertStyle = NSInformationalAlertStyle
                alert.addButtonWithTitle("Yeah!")
                response = alert.runModal
            end

            item 'Preferences' do |sender|
                prefwindow.makeKeyAndOrderFront(sender)
                prefwindow.orderFrontRegardless
                #numberFormatter = NSNumberFormatter.new

                #newAttributes = NSMutableDictionary.dictionary
                
                #numberFormatter.setFormat("###,##0;(###,##0)")
                
                #                [newAttributes setObject(NSColor.redColor, forKey:@"NSColor"];
                #                [numberFormatter setTextAttributesForNegativeValues: newAttributes];
                
                
                #port.cell.setFormatter(numberFormatter)
            end
            
            item 'Open URL' do |sender|
                url = NSURL.URLWithString("http://www.stackoverflow.com/");
                if !NSWorkspace.sharedWorkspace.openURL(url)
                    puts("Failed to open url: #{url.description}");
                end
            end
            
            nest 'Project' do
                task1 = item 'Task1' do |sender|
                    puts "Task1"
                    p sender
                end
                item 'Task2' do |sender|
                    task1.enabled = !task1.isEnabled
                end
                nest 'Task3' do
                    item 'Subtask 1' do
                        puts "Task3/Subtask 1"
                    end
                end
            end
            
            item 'Notification Center' do |sender|
                notify = NSUserNotification.alloc.init
                notify.title = 'Title of notification'
                notify.informativeText = 'Body of notification'
                NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(notify)
            end
            
            separator
            
            item 'Quit' do |sender|
                app = NSApplication.sharedApplication
                app.terminate(self)
            end
        end
    end
    
    def initStatusBar(menu)
        status_bar = NSStatusBar.systemStatusBar
        status_item = status_bar.statusItemWithLength(NSVariableStatusItemLength)
        status_item.setMenu menu
        img = NSImage.imageNamed 'mail.png'
        status_item.setImage(img)
        # status_item.title = "StatusBarSample!"
        status_item.highlightMode = true
    end
    
    def applicationDidFinishLaunching(a_notification)
        app = NSApplication.sharedApplication
        initStatusBar(setupMenu())
        
        puts "Your Application code here."
        app.run
    end
end
