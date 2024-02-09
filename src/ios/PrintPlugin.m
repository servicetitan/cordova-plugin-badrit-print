//
//  PrintPlugin.m
//  Print Plugin
//
//  Created by Ian Tipton (github.com/itip) on 02/07/2011.
//  Copyright 2011 Ian Tipton. All rights reserved.
//  MIT licensed
//

#import "PrintPlugin.h"

@interface PrintPlugin (Private)<WKNavigationDelegate>
- (void)doPrint;
- (void)callbackWithFunction:(NSString *)function withData:(NSString *)value;
- (BOOL)isPrintServiceAvailable;

@end

@interface PrintPlugin ()
@property (nonatomic) NSString *callbackId;
@end

@implementation PrintPlugin

@synthesize successCallback, failCallback, printHTML, dialogTopPos, dialogLeftPos, callbackId;

/*
 Is printing available. Callback returns true/false if printing is available/unavailable.
 */
- (void)isPrintingAvailable: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:([self isPrintServiceAvailable] ? YES : NO)];
  [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
}

- (void)print: (CDVInvokedUrlCommand*)command {
  NSUInteger argc = [command.arguments count];
  if (argc < 1) { return; }
  self.callbackId = command.callbackId;
  self.printHTML = [command.arguments objectAtIndex:0];
  
  if (![self isPrintServiceAvailable]){
    [self callbackWithFunction:self.failCallback withData: @"{success: false, available: false}"];
    return;
  }
  
  UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
  
  if (!controller){
    return;
  }
  
  if ([UIPrintInteractionController isPrintingAvailable]){
    //Set the printer settings
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    
    WKWebView *wkWebView = [[WKWebView alloc] init];
    [wkWebView setNavigationDelegate: self];
    [wkWebView loadHTMLString:self.printHTML baseURL:nil];
    
    UIPrintPageRenderer* renderer = [[UIPrintPageRenderer alloc] init];
    [renderer addPrintFormatter: [wkWebView viewPrintFormatter] startingAtPageAtIndex: 0];
    
    controller.printPageRenderer = renderer;
    controller.printInfo = printInfo;
    controller.showsNumberOfCopies = NO;
  }
}

- (BOOL)isPrintServiceAvailable {
  Class myClass = NSClassFromString(@"UIPrintInteractionController");
  if (myClass) {
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    return (controller != nil) && [UIPrintInteractionController isPrintingAvailable];
  }
  return NO;
}

// MARK: - WKWebViewNavigation delegate

- (void)webView: (WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
  __weak PrintPlugin *weakSelf = self;

  void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
  ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
    CDVPluginResult* pluginResult = nil;
    if (!completed) {
      pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString: [NSString stringWithFormat:@"{success: false, available: true, error: \"%@\"}", error.localizedDescription]];
    }
    else{
      pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"{success: true}"];
    }
    [self.commandDelegate sendPluginResult: pluginResult callbackId: weakSelf.callbackId];
    weakSelf.callbackId = nil;
  };
  
  /*
   If iPad, and if button offsets passed, then show dialog from offset
   */
  
  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    CGRect bounds = self.webView.bounds;
    self.dialogLeftPos = (bounds.size.width / 2) ;
    self.self.dialogTopPos = (bounds.size.height/2);
    
    [controller presentFromRect:CGRectMake(self.dialogLeftPos, self.dialogTopPos, 0, 0) inView: self.webView animated: YES completionHandler: completionHandler];
  } else {
    [controller presentAnimated: YES completionHandler: completionHandler];
  }
}

@end
