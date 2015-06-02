//
//  AddTagController.h
//  MinimalNote
//
//  Created by Carl Li on 6/1/15.
//  Copyright (c) 2015 Carl Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"
#import "BaseHeader.h"

@interface AddTagController : BaseViewController<UITableViewDataSource, UITableViewDelegate>
- (void)setTag:(Tag*) tag;
@end
