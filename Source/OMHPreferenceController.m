/**
 * @file OMHPreferenceController.m
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

#import "OMHPreferenceController.h"

// Preference constants
NSString *OMHActivateAppKey = @"activateKey";
NSString *OMHActivateAppModifierKey = @"activateModifier";
NSString *OMHRapidPasteKey = @"rapidPasteKey";
NSString *OMHRapidPasteModifierKey = @"rapidPasteModifier";
NSString *OMHClippingPurgeLimitKey = @"clippingPurgeLimit";
NSString *OMHAppHasLaunchedBeforeKey = @"hasLaunchedBefore";
NSString *OMHHideAppOnDeactiveKey = @"hideOnDeactivate";
NSString *OMHFocusSearchOnActivateKey = @"focusOnActivate";

// Shortcut identifier constants.
NSString *OMHShortcutActivateAppId = @"OMHActivateApp";
NSString *OMHShortcutRapidPasteId = @"OHMRapidPaste";

// Holds shared singleton instance
static OMHPreferenceController *_sharedPrefsWindowController = nil;


@implementation OMHPreferenceController

@synthesize delegate;

+ (OMHPreferenceController *) sharedWindowController
{
	if ( !_sharedPrefsWindowController ) 
    {
		_sharedPrefsWindowController = [[self alloc] initWithWindowNibName:[self nibName]];
	}

	return _sharedPrefsWindowController;
}


#pragma mark -
#pragma mark Overriding Methods

/**
 * Initializes the main window
 *
 * @param window An instance of NSWindow
 * @return Instance of NSObject
 */
- (id) initWithWindow:(NSWindow *)window
{
    id obj = [super initWithWindow:window];
    [obj setAnimationDuration:0.15];
    
    return obj;
}

- (void) setupToolbar
{
    [self addView:generalPrefsView label:@"General" image:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
    [self addView:shortcutsPrefView label:@"Shortcuts" image:[NSImage imageNamed:@"Shortcuts"]];
    [self addView:updatePrefView label:@"Update" image:[NSImage imageNamed:@"Update"]];
}

- (IBAction) showWindow:(id)sender 
{
    [super showWindow:sender];
    
    [activateControl setDelegate:self];
    [rapidPasteControl setDelegate:self];
    
    [self loadHotKeyFromUserDefaults];
}


#pragma mark -
#pragma mark Keyboard Shortcut Preference Methods

/**
 * Loads global activation hot key from user defaults.
 *
 * The global activation hot key will be loaded from user defaults,
 * registered using the OMHHotKey class and the hot key recorder controller
 * in the preference pane will be updated with the hot key.
 */
- (void) loadHotKeyFromUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    signed short activateKey = [[defaults objectForKey:OMHActivateAppKey] shortValue];
    unsigned int activateModifier = [[defaults objectForKey:OMHActivateAppModifierKey] unsignedIntValue];
    KeyCombo keyCombo = SRMakeKeyCombo( activateKey, SRCarbonToCocoaFlags( activateModifier ) );
    [activateControl setKeyCombo:keyCombo];

    signed short rapidPasteKey = [[defaults objectForKey:OMHRapidPasteKey] shortValue];
    unsigned int rapidPasteModifier = [[defaults objectForKey:OMHRapidPasteModifierKey] unsignedIntValue];    
    keyCombo = SRMakeKeyCombo( rapidPasteKey, SRCarbonToCocoaFlags( rapidPasteModifier ) );
    [rapidPasteControl setKeyCombo:keyCombo]; 
    
    [self tellDelegateShortcutDidChange:OMHShortcutActivateAppId keyCombo:SRMakeKeyCombo( activateKey, activateModifier )];
    [self tellDelegateShortcutDidChange:OMHShortcutRapidPasteId keyCombo:SRMakeKeyCombo( rapidPasteKey, rapidPasteModifier )];
}


/**
 * SRRecorderControl delegate method, called by a SRRecorderControl instance when
 * a keyboard shortcut has been updated.
 *
 * @param recorder An instance of the SRRecorderControl that changed.
 * @param keyCombo KeyCombo struct that contains the new keyboard shortcut.
 */
- (void) shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)keyCombo
{
    keyCombo.flags = SRCocoaToCarbonFlags( keyCombo.flags );
    
    if ( recorder == activateControl )
    {        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithShort:keyCombo.code] forKey:OMHActivateAppKey];
        [defaults setObject:[NSNumber numberWithUnsignedInt:keyCombo.flags] forKey:OMHActivateAppModifierKey];        

        [self tellDelegateShortcutDidChange:OMHShortcutRapidPasteId keyCombo:keyCombo];
    }
    else if ( recorder == rapidPasteControl )
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithShort:keyCombo.code] forKey:OMHRapidPasteKey];
        [defaults setObject:[NSNumber numberWithUnsignedInt:keyCombo.flags] forKey:OMHRapidPasteModifierKey];                

        [self tellDelegateShortcutDidChange:OMHShortcutRapidPasteId keyCombo:keyCombo];
    }
}

/**
 * Notifies the delegate that a shortcut has been changed
 */
- (void) tellDelegateShortcutDidChange:(NSString *)shortcutId keyCombo:(KeyCombo)keyCombo;
{
    if ( [self.delegate respondsToSelector:@selector( shortcutDidChange:keyCombo: )] )
    {
        NSValue *value = [NSValue value:&keyCombo withObjCType:@encode( KeyCombo )];
        [self.delegate performSelector:@selector( shortcutDidChange:keyCombo: ) 
                            withObject:shortcutId 
                            withObject:value];
    }
}

@end
