//
//  MPDocumentSettingsWindowController.m
//  MacPass
//
//  Created by Michael Starke on 26.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "MPDatabaseSettingsWindowController.h"
#import "MPDocument.h"
#import "MPDocumentWindowController.h"
#import "MPDatabaseVersion.h"
#import "MPIconHelper.h"
#import "MPSettingsHelper.h"
#import "MPNumericalInputFormatter.h"

#import "KeePassKit/KeePassKit.h"

#import "HNHUi/HNHUi.h"

#import "KPKNode+IconImage.h"

@interface MPDatabaseSettingsWindowController () {
  NSString *_missingFeature;
}

@end

@implementation MPDatabaseSettingsWindowController

- (NSString *)windowNibName {
  return @"DatabaseSettingsWindow";
}

- (id)initWithWindow:(NSWindow *)window {
  self = [super initWithWindow:window];
  if(self) {
    _missingFeature = NSLocalizedString(@"KDBX_ONLY_FEATURE", "Feature only available in kdbx databases");
  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  NSAssert(self.document != nil, @"Document needs to be present");
    
  self.sectionTabView.delegate = self;
  self.encryptionRoundsTextField.formatter = [[MPNumericalInputFormatter alloc] init];
}

#pragma mark Actions

- (IBAction)save:(id)sender {
  /* General */
  KPKMetaData *metaData = ((MPDocument *)self.document).tree.metaData;
  metaData.databaseDescription = self.databaseDescriptionTextView.string;
  metaData.databaseName = self.databaseNameTextField.stringValue;

  NSInteger compressionIndex = self.databaseCompressionPopupButton.indexOfSelectedItem;
  if(compressionIndex >= KPKCompressionNone && compressionIndex < KPKCompressionCount) {
    metaData.compressionAlgorithm = (uint32_t)compressionIndex;
  }
  NSColor *databaseColor = self.databaseColorColorWell.color;
  if([databaseColor isEqual:[NSColor clearColor]]) {
    metaData.color = nil;
  }
  else {
    metaData.color = databaseColor;
  }
    
  /* Advanced */
  metaData.useTrash = HNHUIBoolForState(self.enableTrashCheckButton.state);
  NSMenuItem *trashMenuItem = self.selectTrashGoupPopUpButton.selectedItem;
  KPKGroup *trashGroup = trashMenuItem.representedObject;
  ((MPDocument *)self.document).tree.trash  = trashGroup;
  
  NSMenuItem *templateMenuItem = self.templateGroupPopUpButton.selectedItem;
  KPKGroup *templateGroup = templateMenuItem.representedObject;
  ((MPDocument *)self.document).templates = templateGroup;
  
  
  BOOL enforceMasterKeyChange = HNHUIBoolForState(self.enforceKeyChangeCheckButton.state);
  BOOL recommendMasterKeyChange = HNHUIBoolForState(self.recommendKeyChangeCheckButton.state);
  
  enforceMasterKeyChange &= (self.enforceKeyChangeIntervalTextField.stringValue.length != 0);
  recommendMasterKeyChange &= (self.recommendKeyChangeIntervalTextField.stringValue.length != 0);
  
  NSInteger enfoceInterval = self.enforceKeyChangeIntervalTextField.integerValue;
  NSInteger recommendInterval = self.recommendKeyChangeIntervalTextField.integerValue;

  metaData.masterKeyChangeEnforcementInterval = enforceMasterKeyChange ? enfoceInterval : -1;
  metaData.masterKeyChangeRecommendationInterval = recommendMasterKeyChange ? recommendInterval : -1;
  
  /* Security */
  
  metaData.protectNotes =  HNHUIBoolForState(self.protectNotesCheckButton.state);
  metaData.protectPassword = HNHUIBoolForState(self.protectPasswortCheckButton.state);
  metaData.protectTitle = HNHUIBoolForState(self.protectTitleCheckButton.state);
  metaData.protectUrl = HNHUIBoolForState(self.protectURLCheckButton.state);
  metaData.protectUserName = HNHUIBoolForState(self.protectUserNameCheckButton.state);
  
  metaData.defaultUserName = self.defaultUsernameTextField.stringValue;
  
  /*
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:protectNotes forKey:kMPSettingsKeyLegacyHideNotes];
    [defaults setBool:protectPassword forKey:kMPSettingsKeyLegacyHidePassword];
    [defaults setBool:protectTitle forKey:kMPSettingsKeyLegacyHideTitle];
    [defaults setBool:protectURL forKey:kMPSettingsKeyLegacyHideURL];
    [defaults setBool:protectUsername forKey:kMPSettingsKeyLegacyHideUsername];
    [defaults synchronize];
   */
  
  metaData.rounds = MAX(0,self.encryptionRoundsTextField.integerValue);
  /* Register an action to enable promts when user cloeses without saving */
  [self.document updateChangeCount:NSChangeDone];
  [self close:nil];
}

- (IBAction)close:(id)sender {
  [self dismissSheet:0];
}

- (IBAction)benchmarkRounds:(id)sender {
  [self.benchmarkButton setEnabled:NO];
  [KPKCompositeKey benchmarkTransformationRounds:1 completionHandler:^(NSUInteger rounds) {
    self.encryptionRoundsTextField.integerValue = rounds;
    self.benchmarkButton.enabled = YES;
  }];
}

- (void)updateView {
  if(!self.isDirty) {
    return;
  }
  if(!self.document) {
    return; // no document, just leave
  }
  /* Update all stuff that might have changed */
  KPKMetaData *metaData = ((MPDocument *)self.document).tree.metaData;
  [self _setupDatabaseTab:metaData];
  [self _setupProtectionTab:metaData];
  [self _setupAdvancedTab:((MPDocument *)self.document).tree];
  self.isDirty = NO;
}

- (void)showSettingsTab:(MPDatabaseSettingsTab)tab {
  /*
   We need to make sure the window is loaded
   so we just call the the getter and let the loading commence
   */
  if(![self window]) {
    return;
  }
  [self.sectionTabView selectTabViewItemAtIndex:tab];
}

#pragma mark NSTableViewDelegate
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
  NSUInteger index = [tabView indexOfTabViewItem:tabViewItem];
  switch ((MPDatabaseSettingsTab)index) {
    case MPDatabaseSettingsTabSecurity:
    case MPDatabaseSettingsTabAdvanced:
    case MPDatabaseSettingsTabGeneral:
      return YES;
      
    default:
      return NO;
  }
}

#pragma mark Private Helper
- (void)_setupDatabaseTab:(KPKMetaData *)metaData {
  self.databaseNameTextField.stringValue = metaData.databaseName;
  self.databaseDescriptionTextView.string = metaData.databaseDescription;
  [self.databaseCompressionPopupButton selectItemAtIndex:metaData.compressionAlgorithm];
  NSColor *databaseColor = metaData.color ? metaData.color : [NSColor clearColor];
  self.databaseColorColorWell.color = databaseColor;
}

- (void)_setupProtectionTab:(KPKMetaData *)metaData {
  self.protectNotesCheckButton.state = HNHUIStateForBool(metaData.protectNotes);
  self.protectPasswortCheckButton.state = HNHUIStateForBool(metaData.protectPassword);
  self.protectTitleCheckButton.state = HNHUIStateForBool(metaData.protectTitle);
  self.protectURLCheckButton.state = HNHUIStateForBool(metaData.protectUrl);
  self.protectUserNameCheckButton.state = HNHUIStateForBool(metaData.protectUserName);

  [self.encryptionRoundsTextField setIntegerValue:metaData.rounds];
  [self.benchmarkButton setEnabled:YES];
}

- (void)_setupAdvancedTab:(KPKTree *)tree {
  HNHUISetStateFromBool(self.enableTrashCheckButton, tree.metaData.useTrash);
  self.selectTrashGoupPopUpButton.enabled = tree.metaData.useTrash;
  [self.enableTrashCheckButton bind:NSValueBinding toObject:self.selectTrashGoupPopUpButton withKeyPath:NSEnabledBinding options:nil];
  [self _updateTrashFolders:tree];
  
  self.defaultUsernameTextField.stringValue = tree.metaData.defaultUserName;
  self.defaultUsernameTextField.editable = YES;
  [self _updateTemplateGroup:tree];
  
  HNHUISetStateFromBool(self.enforceKeyChangeCheckButton, tree.metaData.enforceMasterKeyChange);
  HNHUISetStateFromBool(self.recommendKeyChangeCheckButton, tree.metaData.recommendMasterKeyChange);
  [self.enforceKeyChangeIntervalTextField setEnabled:tree.metaData.enforceMasterKeyChange];
  [self.recommendKeyChangeIntervalTextField setEnabled:tree.metaData.recommendMasterKeyChange];

  self.enforceKeyChangeIntervalTextField.stringValue = @"";
  if(tree.metaData.enforceMasterKeyChange) {
    self.enforceKeyChangeIntervalTextField.integerValue = tree.metaData.masterKeyChangeEnforcementInterval;
  }
  self.recommendKeyChangeIntervalTextField.stringValue = @"";
  if(tree.metaData.recommendMasterKeyChange) {
    self.recommendKeyChangeIntervalTextField.integerValue = tree.metaData.masterKeyChangeRecommendationInterval;
  }
  [self.enforceKeyChangeCheckButton bind:NSValueBinding toObject:self.enforceKeyChangeIntervalTextField withKeyPath:NSEnabledBinding options:nil];
  [self.recommendKeyChangeCheckButton bind:NSValueBinding toObject:self.recommendKeyChangeIntervalTextField withKeyPath:NSEnabledBinding options:nil];
}

- (void)_updateFirstResponder {
  NSTabViewItem *selected = self.sectionTabView.selectedTabViewItem;
  MPDatabaseSettingsTab tab = [self.sectionTabView.tabViewItems indexOfObject:selected];
  
  switch(tab) {
    case MPDatabaseSettingsTabAdvanced:
      [self.window makeFirstResponder:self.defaultUsernameTextField];
      break;
      
    case MPDatabaseSettingsTabSecurity:
      [self.window makeFirstResponder:self.protectTitleCheckButton];
      break;
      
    case MPDatabaseSettingsTabGeneral:
      [self.window makeFirstResponder:self.databaseNameTextField];
      break;
  }
}

- (void)_updateTrashFolders:(KPKTree *)tree {
  NSMenu *menu = [self _buildTrashTreeMenu:tree];
  self.selectTrashGoupPopUpButton.menu = menu;
}

- (void)_updateTemplateGroup:(KPKTree *)tree {
  NSMenu *menu = [self _buildTemplateTreeMenu:tree];
  self.templateGroupPopUpButton.menu = menu;
}

- (NSMenu *)_buildTrashTreeMenu:(KPKTree *)tree {
  NSMenu *menu = [self _buildTreeMenu:tree preselect:tree.metaData.trashUuid];
  
  NSMenuItem *selectItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"AUTOCREATE_TRASH_FOLDER", @"Menu item for automatic trash creation")
                                                      action:NULL
                                               keyEquivalent:@""];
  selectItem.enabled = YES;
  [menu insertItem:selectItem atIndex:0];
  
  return menu;
}

- (NSMenu *)_buildTemplateTreeMenu:(KPKTree *)tree {
  NSMenu *menu = [self _buildTreeMenu:tree preselect:tree.metaData.entryTemplatesGroup];
  
  NSMenuItem *selectItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"NO_TEMPLATE_GROUP", @"Menu item to reset the template groups")
                                                      action:NULL
                                               keyEquivalent:@""];
  selectItem.enabled = YES;
  [menu insertItem:selectItem atIndex:0];
  
  return menu;
}


- (NSMenu *)_buildTreeMenu:(KPKTree *)tree preselect:(NSUUID *)uuid {
  NSMenu *menu = [[NSMenu alloc] init];
  menu.autoenablesItems = NO;
  for(KPKGroup *group in tree.root.groups) {
    [self _insertMenuItemsForGroup:group atLevel:0 inMenu:menu preselect:uuid];
  }
  return menu;
}

- (void)_insertMenuItemsForGroup:(KPKGroup *)group atLevel:(NSUInteger)level inMenu:(NSMenu *)menu preselect:(NSUUID *)uuid{
  NSMenuItem *groupItem = [[NSMenuItem alloc] init];
  groupItem.image = group.iconImage;
  groupItem.title = group.title;
  groupItem.representedObject = group;
  groupItem.enabled = YES;
  if(uuid && [group.uuid isEqual:uuid]) {
    groupItem.state = NSOnState;
  }
  groupItem.indentationLevel = level;
  [menu addItem:groupItem];
  for(KPKGroup *childGroup in group.groups) {
    [self _insertMenuItemsForGroup:childGroup atLevel:level + 1 inMenu:menu preselect:uuid];
  }
}

@end
