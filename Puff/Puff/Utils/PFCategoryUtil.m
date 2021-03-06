//
//  PFCategoryUtil.m
//  Puff
//
//  Created by bob.sun on 17/10/2016.
//  Copyright © 2016 bob.sun. All rights reserved.
//

#import "PFCategoryUtil.h"

#include "Constants.h"

#import "PFCategoryManager.h"
#import "PFCategory.h"
#import "PFTypeManager.h"
#import "PFType.h"
#import "PFKeychainHelper.h"

@interface PFCategoryUtil ()
@property (strong, nonatomic) NSArray *categories;
@property (strong, nonatomic) NSArray *catNames;
@property (strong, nonatomic) NSArray *catIds;

@property (strong, nonatomic) NSString *libPath;

@property (assign, nonatomic) NSInteger typeId;
@end

@implementation PFCategoryUtil

- (void)initBuiltins {
    BOOL newInstall = [[NSUserDefaults standardUserDefaults] objectForKey:kPFNewInstall] == nil;
    if (newInstall) {
        //New Install, delete keychain
        [[PFKeychainHelper sharedInstance] cleanMasterPassword];
        //Save built in categories for new install only.
        self.typeId = 0;
        [self _copyFiles];
        [self _initNames];
        [self initBuiltInCategories];
        [self initBuiltInTypes];
        [[NSUserDefaults standardUserDefaults] setBool:@(1) forKey:kPFNewInstall];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)initBuiltInCategories {
    PFCategoryManager *manager = [PFCategoryManager sharedManager];
    PFCategory *cat = nil;
    
    NSString *catFolder = @"/icon_category";
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Recent";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdRecent;
    cat.icon = [catFolder stringByAppendingString:@"/cat_recent.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Cards";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdCards;
    cat.icon = [catFolder stringByAppendingString:@"/cat_cards.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Computers";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdComputers;
    cat.icon = [catFolder stringByAppendingString:@"/cat_computer.png"];    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Devices";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdDevices;
    cat.icon = [catFolder stringByAppendingString:@"/cat_device.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Entry";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdEntry;
    cat.icon = [catFolder stringByAppendingString:@"/cat_entry.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Mail";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdMail;
    cat.icon = [catFolder stringByAppendingString:@"/cat_mail.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Social";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdSocial;
    cat.icon = [catFolder stringByAppendingString:@"/cat_social.png"];
    [manager saveCategory:cat];
    
    cat = [[PFCategory alloc] init];
    cat.name = @"Website";
    cat.type = catTypeBuiltIn;
    cat.identifier = catIdWebsite;
    cat.icon = [catFolder stringByAppendingString:@"/cat_website.png"];
    [manager saveCategory:cat];
    
    _categories = [manager fetchAll];
    
}

- (void)initBuiltInTypes {
    
    NSURL *typeFolderUrl = nil;
    
    for (int i = 0; i < self.catNames.count; i++) {
//        typeFolderUrl = [NSURL fileURLWithPath:
//                                                 [_libPath stringByAppendingString:self.catNames[i]]
//                                   isDirectory: YES];
        typeFolderUrl = [[NSURL URLWithString:_libPath] URLByAppendingPathComponent:self.catNames[i] isDirectory:YES];
        
        [self _loopFolderAddType:typeFolderUrl andCategoryId:[self.catIds[i] longLongValue]];
    }

}

- (void)_loopFolderAddType:(NSURL*)typeFolderUrl andCategoryId:(uint64_t)catId {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    PFTypeManager *tm = [PFTypeManager sharedManager];
    PFType *toAdd = nil;
    
    NSDirectoryEnumerator *dEnum = [fm enumeratorAtURL:typeFolderUrl includingPropertiesForKeys:@[NSURLNameKey] options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        return YES;
    }];
    
    for (NSURL *url in dEnum) {
        toAdd = [[PFType alloc] init];
        toAdd.name = [url.lastPathComponent stringByReplacingOccurrencesOfString:@".png" withString:@""];
        toAdd.category = catId;
        toAdd.icon = [[@"/" stringByAppendingString:[url.pathComponents objectAtIndex:url.pathComponents.count - 2] ] stringByAppendingString: [@"/" stringByAppendingString:url.lastPathComponent]];
        toAdd.identifier = _typeId;
        _typeId += 1;
        [tm saveType:toAdd];
    }
}

- (void) _initNames {
    self.catNames = @[@"cat_cards", @"cat_computers", @"cat_device", @"cat_entry", @"cat_mail", @"cat_social", @"cat_website"];
    self.catIds = @[@(catIdCards), @(catIdComputers), @(catIdDevices), @(catIdEntry), @(catIdMail), @(catIdSocial), @(catIdWebsite)];
    
}

- (void)_copyFiles {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(
                                                             NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    libPath = [libPath stringByAppendingString:@"/cats"];
    NSError *err;
    NSString *resPath = [[NSBundle bundleForClass:self.class] pathForResource:kAssetsFolder ofType:nil];
    NSURL *resURL = [NSURL fileURLWithPath:resPath isDirectory:YES];
    NSURL *libURL = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.sun.bob.leela"] URLByAppendingPathComponent:@"cats" isDirectory:YES];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm copyItemAtURL:resURL toURL:libURL error:&err];
    _libPath = [libURL absoluteString];
}

@end
