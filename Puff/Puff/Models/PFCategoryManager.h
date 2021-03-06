//
//  PFCategoryManager.h
//  Puff
//
//  Created by bob.sun on 16/10/2016.
//  Copyright © 2016 bob.sun. All rights reserved.
//

#import "PFDBManager.h"
#import "PFCategory.h"

static NSString * const kEntityNamePFCategory       = @"PFCategory";

@class _PFCategory;
@interface PFCategoryManager : NSObject

+ (instancetype)sharedManager;

- (NSError*)saveCategory:(PFCategory*)category;
- (NSError*)saveCategoryFromDict:(NSDictionary*)dict;

-(NSArray*)fetchAll;
-(NSArray*)fetchCategoryByType:(int64_t)typeId;
- (PFCategory*)fetchCategoryById:(int64_t)identifier;

@end
