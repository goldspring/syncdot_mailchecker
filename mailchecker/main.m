//
//  main.m
//  mailchecker
//
//  Created by on 2013/03/17.
//  Copyright (c) 2013. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
