//
//  MPDocumentSettingsWindowController.h
//  MacPass
//
//  Created by Michael Starke on 26.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HNHUi/HNHUi.h>

typedef NS_ENUM(NSUInteger, MPDatabaseSettingsTab) {
  MPDatabaseSettingsTabGeneral,
  MPDatabaseSettingsTabSecurity,
  MPDatabaseSettingsTabAdvanced
};

@class MPDocument;
@class HNHRoundedTextField;

@interface MPDatabaseSettingsWindowController : HNHUISheetWindowController <NSTextFieldDelegate, NSTabViewDelegate>

@property (weak) IBOutlet NSTabView *sectionTabView;

/* General Tab */
@property (weak) IBOutlet NSTextField *databaseNameTextField;
@property (weak) IBOutlet NSPopUpButton *databaseCompressionPopupButton;
@property (unsafe_unretained) IBOutlet NSTextView *databaseDescriptionTextView;
@property (weak) IBOutlet NSColorWell *databaseColorColorWell;

/* Security Tab */
@property (weak) IBOutlet NSButton *protectTitleCheckButton;
@property (weak) IBOutlet NSButton *protectUserNameCheckButton;
@property (weak) IBOutlet NSButton *protectPasswortCheckButton;
@property (weak) IBOutlet NSButton *protectURLCheckButton;
@property (weak) IBOutlet NSButton *protectNotesCheckButton;
@property (weak) IBOutlet NSTextField *encryptionRoundsTextField;
@property (weak) IBOutlet NSButton *benchmarkButton;

/* Advanced Tab*/
@property (weak) IBOutlet NSButton *enableTrashCheckButton;
@property (weak) IBOutlet NSButton *emptyTrashOnQuitCheckButton;
@property (weak) IBOutlet NSPopUpButton *selectTrashGoupPopUpButton;
@property (weak) IBOutlet NSTextField *defaultUsernameTextField;
@property (weak) IBOutlet NSPopUpButton *templateGroupPopUpButton;

@property (weak) IBOutlet NSButton *recommendKeyChangeCheckButton;
@property (weak) IBOutlet NSButton *enforceKeyChangeCheckButton;
@property (weak) IBOutlet NSTextField *recommendKeyChangeIntervalTextField;
@property (weak) IBOutlet NSTextField *enforceKeyChangeIntervalTextField;

- (void)showSettingsTab:(MPDatabaseSettingsTab)tab;

@end


