//
//  PrintPlugin.m
//  Print Plugin
//
//  Created by Ian Tipton (github.com/itip) on 02/07/2011.
//  Copyright 2011 Ian Tipton. All rights reserved.
//  MIT licensed
//

#import "PrintPlugin.h"

@interface PrintPlugin (Private)
-(void) doPrint;
-(void) callbackWithFuntion:(NSString *)function withData:(NSString *)value;
- (BOOL) isPrintServiceAvailable;
@end

@implementation PrintPlugin

@synthesize successCallback, failCallback, printHTML, dialogTopPos, dialogLeftPos;

/*
 Is printing available. Callback returns true/false if printing is available/unavailable.
 */
 - (void) isPrintingAvailable:(CDVInvokedUrlCommand*)command{
    NSUInteger argc = [command.arguments count];
    
//    if (argc < 0) {
//        return;
//    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:([self isPrintServiceAvailable] ? YES : NO)];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) print:(CDVInvokedUrlCommand*)command{
    NSUInteger argc = [command.arguments count];
    NSLog(@"Array contents: %@", command.arguments);
    if (argc < 1) {
        return;
    }
    self.printHTML = [command.arguments objectAtIndex:0];
    
    if (![self isPrintServiceAvailable]){
        [self callbackWithFuntion:self.failCallback withData: @"{success: false, available: false}"];
        
        return;
    }
    
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    
    if (!controller){
        return;
    }
    
    if ([UIPrintInteractionController isPrintingAvailable]){
        //Set the priner settings
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;

        UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc]
            initWithMarkupText:self.printHTML
        ];

        formatter.startPage = 0;
        formatter.contentInsets = UIEdgeInsetsMake(1, 1, 1, 1);

        UIPrintPageRenderer* renderer = [[UIPrintPageRenderer alloc] init];
        [renderer addPrintFormatter : formatter startingAtPageAtIndex : 0];

        controller.printPageRenderer = renderer;
        controller.printInfo = printInfo;
        controller.showsPageRange = NO;
        controller.showsNumberOfCopies = NO;

        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            CDVPluginResult* pluginResult = nil;
            if (!completed) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"{success: false, available: true, error: \"%@\"}", error.localizedDescription]];
            }
            else{
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"{success: true}"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        };
        
        /*
         If iPad, and if button offsets passed, then show dilalog 
         from offset
         */

        if ([UIDevice currentDevice].userInterfaceIdiom  == UIUserInterfaceIdiomPad) {
        
            CGRect bounds = self.webView.bounds;         
            self.dialogLeftPos = (bounds.size.width / 2) ;
            self.self.dialogTopPos = (bounds.size.height/2);
            
            [controller presentFromRect:CGRectMake(self.dialogLeftPos,self.dialogTopPos, 0, 0) inView:self.webView animated:YES completionHandler:completionHandler];
        
        } else {
        [controller presentAnimated:YES completionHandler:completionHandler];
    }
}

}

-(BOOL) isPrintServiceAvailable{
    
    Class myClass = NSClassFromString(@"UIPrintInteractionController");
    if (myClass) {
        UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
        return (controller != nil) && [UIPrintInteractionController isPrintingAvailable];
    }
    
    
    return NO;
}

@end
