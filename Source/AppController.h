/**
 * @file AppController.h
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

#import <Cocoa/Cocoa.h>


@class OMHClippingController;

/**
 * How often we should auto save the data in seconds
 */
extern int const AUTOSAVE_INTERVAL;


@interface AppController: NSObject 
{   
    // Main Window 
    IBOutlet NSWindow *mainWindow;
    
    // Controllers
    IBOutlet OMHClippingController *clippingController;

    // Core data
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;    

    // Other
    NSStatusItem *statusItem;
    NSTimer *autoSaveTimer;
    IBOutlet NSTextField *statusTextField;
    IBOutlet NSSearchField *searchField;
}

#pragma mark -
#pragma mark Properties

/**
 * Holds the status item
 */
@property( nonatomic, retain ) NSStatusItem *statusItem;

/**
 * Holds the main window
 */
@property( nonatomic, retain ) NSWindow *mainWindow;


#pragma mark -
#pragma mark Class methods

/**
 * Returns a shared instance (singleton) of this class
 */
+ (AppController *) sharedAppController;


#pragma mark -
#pragma mark Interface Actions

/**
 * Brings the main window to the front
 */
- (IBAction) showMainWindow:(id)sender;

/**
 * Brings the Preference window to the front
 */
- (IBAction) showPreferencesWindow:(id)sender;

/**
 * Toogles the main window
 */
- (IBAction) toogleMainWindow:(id)sender;

/**
 * Toogles the quick preview window
 */
- (IBAction) toogleQuickPreviewWindow:(id)sender;


#pragma mark -
#pragma mark Instance Methods

/**
 * Creates and sets up the status item
 */
- (void) createStatusMenu;

/** 
 * Flashes the status menu icon (turns it blue temporary).
 */
- (void) flashStatusMenu;

/**
 * Handles the status menu item being clicked event
 */
- (void) statusMenuItemClicked;

/**
 * Returns the activate shortcut key as a string
 */
- (NSString *) activateKeyComboString;

@end
