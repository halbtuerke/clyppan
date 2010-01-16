/**
 * @file AppController.m
 * @author Ole Morten Halvorsen
 *
 * @section LICENSE
 * Copyright (c) 2009, Ole Morten Halvorsen
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this list 
 *   of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, this list
 *   of conditions and the following disclaimer in the documentation and/or other materials 
 *   provided with the distribution.
 * - Neither the name of Clyppan nor the names of its contributors may be used to endorse or 
 *   promote products derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "AppController.h"
#import "OMHShortcutKey.h"
#import "OMHClippingController.h"
#import "OMHClipboardController.h"
#import "OMHPreferenceController.h"
#import "OMHQuickPreviewWindowController.h"
#import "OMHStatusItemWindowController.h"


const int AUTOSAVE_INTERVAL = 10*60;


@implementation AppController

@synthesize statusItem;
@synthesize mainWindow;

#pragma mark -
#pragma mark Class methods

+ (AppController *) sharedAppController
{
    return [NSApp delegate];
}

#pragma mark -
#pragma mark Initialization and Setup

+ (void) initialize;
{
	// Set default values for preferences
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    // Register Ctrl+Command+C as the default short cut
    [defaultValues setObject:[NSNumber numberWithShort:8] forKey:OMHActivateAppKey];
    [defaultValues setObject:[NSNumber numberWithUnsignedInt:768] forKey:OMHActivateAppModifierKey];
    
    // Register Shift+Command+V as the default short cut
    [defaultValues setObject:[NSNumber numberWithShort:9] forKey:OMHRapidPasteKey];
    [defaultValues setObject:[NSNumber numberWithUnsignedInt:768] forKey:OMHRapidPasteModifierKey];
    
    // Set default limit for when to purge old clippings
    [defaultValues setObject:[NSNumber numberWithInt:50] forKey:OMHClippingPurgeLimitKey];
    
    // Set a flag to know if we've ever started before
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:OMHAppHasLaunchedBeforeKey];
    
    // Do not hide on deactivate by default
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:OMHHideAppOnDeactiveKey];
    
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void) awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    

    // Show floating helper window
    if ( ![defaults boolForKey:OMHAppHasLaunchedBeforeKey] )
    {
        [[OMHStatusItemWindowController sharedWindowController] showWindow:self];
    }
 
    // Set self as delegate for handling hot keys
    [[OMHShortcutKey sharedShortcutKey] setDelegate:self];

    // Set up the custom preference controller
    [[OMHPreferenceController sharedWindowController] setDelegate:self];
    [[OMHPreferenceController sharedWindowController] loadHotKeyFromUserDefaults];

    // Observe certain user default keypaths
    [defaults addObserver:self forKeyPath:OMHClippingPurgeLimitKey options:0 context:NULL];
    [clippingController addObserver:self 
                         forKeyPath:@"currentActiveItem" 
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                            context:nil];
    // Set purge limit
    clippingController.clippingPurgeLimit = [[defaults objectForKey:OMHClippingPurgeLimitKey] intValue];    

    // Set window collection behaviour
    [mainWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];  
        
    // Apply an embossed look to the status text
    [statusTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    
    // Set up the clipboard controller
    [[OMHClipboardController sharedController] createTimer];
}

- (void) createStatusMenu
{        
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:27];
    [statusItem setHighlightMode:YES];	 
    [statusItem setTarget:self];
    [statusItem setAction:@selector( statusMenuItemClicked )];       
    [statusItem setImage:[NSImage imageNamed:@"clyppan-small"]];
}


#pragma mark -
#pragma mark Interface Actions

- (IBAction) showMainWindow:(id)sender;
{
    [NSApp activateIgnoringOtherApps:YES]; 
    [mainWindow makeKeyAndOrderFront:self];
}

/**
 * Handles the event of the status menu item getting clicked.
 */
- (void) statusMenuItemClicked
{
    [self toogleMainWindow:self];
}


- (IBAction) showPreferencesWindow:(id)sender
{
    [[OMHPreferenceController sharedWindowController] showWindow:nil];
}

- (IBAction) toogleMainWindow:(id)sender
{
    if ( [mainWindow isKeyWindow] && [mainWindow isVisible] )
    {
        [mainWindow orderOut:self];
        [NSApp hide:self];
    }
    else
    {
        [self showMainWindow:self];
    }    
}

- (IBAction) toogleQuickPreviewWindow:(id)sender
{
    [[OMHQuickPreviewWindowController sharedWindowController] toogleQuickPreviewWindow:self];
}


#pragma mark -
#pragma mark Methods

- (void) flashStatusMenu
{
    [self.statusItem setImage:[NSImage imageNamed:@"clyppan-small-inverted"]];
    [self.statusItem performSelector:@selector( setImage: )
     withObject:[NSImage imageNamed:@"clyppan-small"]
     afterDelay:0.40];
}

- (NSString *) activateKeyComboString
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    signed short activateKey = [[defaults objectForKey:OMHActivateAppKey] shortValue];
    unsigned int activateModifier = [[defaults objectForKey:OMHActivateAppModifierKey] unsignedIntValue];
    
	return [NSString stringWithFormat: @"%@%@",
            SRStringForCocoaModifierFlags( SRCarbonToCocoaFlags( activateModifier ) ),
            SRStringForKeyCode( activateKey )];
}


#pragma mark -
#pragma mark Notifications / Delegation methods

- (void) windowDidBecomeKey:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ( [defaults boolForKey:OMHAppHasLaunchedBeforeKey] )
    {
        [[OMHStatusItemWindowController sharedWindowController] close];
        [defaults setBool:YES forKey:OMHAppHasLaunchedBeforeKey];        
    }
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Start autosaving timer
	autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:AUTOSAVE_INTERVAL
       	  									 target:self
                                           selector:@selector( autoSave )
                                           userInfo:nil 
                                            repeats:YES]; 
}

/**
 * Displays the main window if it's was previously closed. 
 */
- (void) applicationWillBecomeActive:(NSNotification *)aNotification
{
    // Don't show the main window if we're starting up for the first time.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    if ( [defaults boolForKey:OMHAppHasLaunchedBeforeKey] )
    {
        [self showMainWindow:self];
    }
    
    [defaults setBool:YES forKey:OMHAppHasLaunchedBeforeKey];
}

- (void) applicationWillResignActive:(NSNotification *)aNotification
{
    [[OMHStatusItemWindowController sharedWindowController] close];
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:OMHHideAppOnDeactiveKey] )
    {
        [NSApp hide:self];   
    }    
}

/**
 * Callback method, called whenever a global hot key is pressed
 */
- (void) handleHotKey:(NSString *)identifier;
{
    if ( [identifier isEqualTo:OMHShortcutActivateAppId] )
    {
        [self toogleMainWindow:self];
        return;
    }
    
    if ( [identifier isEqualTo:OMHShortcutRapidPasteId] )
    {
        [clippingController rapidPaste];
        return;
    }
}

/**
 * Callback method, called whenever the user has changed a global hotkey preference.
 */
- (void) shortcutDidChange:(NSString *)shortcutId keyCombo:(NSValue *)wrappedKeyCombo;
{
    KeyCombo keyCombo;
    [wrappedKeyCombo getValue:&keyCombo];
    
    OMHShortcutKey *hotKey = [OMHShortcutKey sharedShortcutKey];
    [hotKey unRegisterShortcutKey:shortcutId];  
    [hotKey registerShortcutKey:shortcutId key:keyCombo.code modifier:keyCombo.flags];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if ( [keyPath isEqualToString:OMHClippingPurgeLimitKey] )
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        clippingController.clippingPurgeLimit = [[defaults objectForKey:OMHClippingPurgeLimitKey] intValue];
    }
    
    if ( [keyPath isEqualToString:@"currentActiveItem"] )
    {
        [self flashStatusMenu];
    }
}

@end
