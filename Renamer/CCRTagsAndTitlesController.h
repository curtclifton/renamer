//
//  CCRTagsAndTitlesController.h
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCRTagsAndTitlesController : NSObject <NSComboBoxDataSource>

@property (weak) IBOutlet NSComboBox *tagComboBox;
@property (weak) IBOutlet NSComboBox *titleComboBox;

- (void)clearFieldsAndRemember:(BOOL)remember;

@end
