//
//  QSHAppDelegate.m
//  quark-shell
//
//  Created by Xhacker Liu on 3/25/14.
//  Copyright (c) 2014 Xhacker. All rights reserved.
//

#import "QSHAppDelegate.h"
#import "QSHWebViewDelegate.h"
#import "QSHStatusItemView.h"
#import "NSWindow+Fade.h"

@interface WebPreferences (WebPreferencesPrivate)

- (void)_setLocalStorageDatabasePath:(NSString *)path;
- (void)setLocalStorageEnabled:(BOOL)localStorageEnabled;

@end


@interface QSHAppDelegate () <NSWindowDelegate>

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) QSHStatusItemView *statusItemView;
@property (nonatomic, weak) IBOutlet WebView *webView;
@property (nonatomic) QSHWebViewDelegate *webViewDelegate;

@end

@implementation QSHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // TODO: bundle identifier should be generated from manifest.json
    WebPreferences *webPrefs = [WebPreferences standardPreferences];
    NSString *bundleIdentifier = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
    NSString *applicationSupportFile = [@"~/Library/Application Support/" stringByExpandingTildeInPath];
    NSString *savePath = [NSString pathWithComponents:@[applicationSupportFile, bundleIdentifier, @"LocalStorage"]];
    [webPrefs _setLocalStorageDatabasePath:savePath];
    [webPrefs setLocalStorageEnabled:YES];

    NSStatusBar *bar = [NSStatusBar systemStatusBar];

    self.statusItem = [bar statusItemWithLength:NSSquareStatusItemLength];

    NSImage *statusIcon = [NSImage imageNamed:@"tray-icon"];
    [statusIcon setTemplate:YES];
    self.statusItem.button.image = statusIcon;
    
    // We can't keep the button highlighted by calling `setHighlighted:` or `highlight:`.
    // So we are adding another invisible button as subview to take over the event handler.
    // Then we can call `highlight:` in the event handler.
    // See: http://stackoverflow.com/questions/26004684/nsstatusbarbutton-keep-highlighted
    NSButton *button = [[NSButton alloc] initWithFrame:self.statusItem.button.frame];
    button.alphaValue = 0;
    NSArray *array = @[self.statusItem.button, button];
    self.statusItem.button.superview.subviews = array;

    [button sendActionOn:(NSLeftMouseDownMask | NSRightMouseDownMask)];
    button.target = self;
    button.action = @selector(statusItemClicked);

    self.window.level = NSFloatingWindowLevel;
    self.window.delegate = self;
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];

    self.webView.wantsLayer = YES;
    self.webView.layer.cornerRadius = 5;
    self.webView.layer.masksToBounds = YES;
    [self.webView setDrawsBackground:NO];

    NSString *url = [[NSURL URLWithString:kIndexPath relativeToURL:[[NSBundle mainBundle] resourceURL]] absoluteString];
    self.webView.mainFrameURL = url;

    self.webViewDelegate = [[QSHWebViewDelegate alloc] init];
    self.webViewDelegate.appDelegate = self;
    self.webViewDelegate.statusItem = self.statusItem;
    self.webViewDelegate.statusItemView = self.statusItemView;
    self.webViewDelegate.webView = self.webView;
    self.webView.frameLoadDelegate = self.webViewDelegate;
    self.webView.UIDelegate = self.webViewDelegate;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (!self.pinned) {
        [self hideWindow];
    }
}

- (void)showWindow
{
    self.shouldBeVisible = true;
    [self refreshStyle];

    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)hideWindow
{
    self.shouldBeVisible = false;
    [self refreshStyle];

    [self.window fadeOut];
}

- (void)statusItemClicked
{
    const NSUInteger buttonMask = [NSEvent pressedMouseButtons];
    BOOL primaryDown = ((buttonMask & (1 << 0)) != 0);
    BOOL secondaryDown = ((buttonMask & (1 << 1)) != 0);
    if (primaryDown) {
        if (self.clickCallback) {
            self.clickCallback();
        }
    }
    if (secondaryDown) {
        if (self.secondaryClickCallback) {
            self.secondaryClickCallback();
        }
    }
    
    if (self.window.visible) {
        [self hideWindow];
    }
    else {
        [self showWindow];
    }
}

- (void)refreshStyle
{
    [self.statusItem.button highlight:self.shouldBeVisible];
    
    NSRect itemFrame;

    itemFrame = self.statusItem.button.window.frame;

    NSRect windowFrame = self.window.frame;
    windowFrame.origin.x = NSMidX(itemFrame) - NSWidth(windowFrame) / 2.0;
    windowFrame.origin.y = NSMinY(itemFrame) - NSHeight(windowFrame);
    [self.window setFrame:windowFrame display:NO];
}

@end
