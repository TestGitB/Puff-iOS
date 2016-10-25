//
//  MasterViewController.m
//  Puff
//
//  Created by bob.sun on 16/9/14.
//  Copyright © 2016年 bob.sun. All rights reserved.
//

#import "MasterViewController.h"

#import "PFDrawerViewController.h"
#import "AppDelegate.h"

#import <MaterialControls/MDButton.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>

#import "PFBlowfish.h"
#import "NSObject+Events.h"
#import "PFResUtil.h"
#include "Constants.h"
#import "MainAccountCell.h"
#import "PFAddAccountViewController.h"

#import "PFAccountManager.h"

@interface MasterViewController () <PFDrawerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) AppDelegate *app;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *toolbar;
@property (weak, nonatomic) IBOutlet MDButton *addButton;
@property (weak, nonatomic) IBOutlet UIView *rippleView;
@property (weak, nonatomic) IBOutlet UITextField *lockPasswordField;
@property (weak, nonatomic) IBOutlet UIButton *lockTouchIdIcon;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rippleHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rippleWidth;

@property (weak, nonatomic) IBOutlet UIView *lockView;
@property (strong, nonatomic) NSArray<PFAccount*> *data;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _initUI];
    [self subscribe:UIApplicationWillResignActiveNotification selector:@selector(lockViews)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    _lockView.hidden = !_app.locked;
    if (_app.locked) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_dismissLockView) name:UIKeyboardDidHideNotification object:nil];
    } else {
        [self _loadInitCategory];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !_app.locked) {
        return _data.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainAccountCell *ret = [tableView dequeueReusableCellWithIdentifier:kMainAccountCellReuseId];
    [ret configWithAccount:_data[indexPath.row]];
    return ret;
}

#pragma mark - UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 260;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - IBActions
- (IBAction)didClickAddButton:(id)sender {
    _rippleView.backgroundColor = _addButton.backgroundColor;
    
    CGFloat fullSize = [PFResUtil screenSize].size.height * 2;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fromValue = [NSNumber numberWithFloat:28];
    animation.toValue = [NSNumber numberWithFloat:fullSize / 2];
    animation.duration = 0.4;
    [_rippleView.layer addAnimation:animation forKey:@"cornerRadius"];
    
    [_rippleView.layer setCornerRadius:fullSize / 2];
    
    [UIView animateWithDuration:0.4 animations:^{
        _rippleView.bounds = CGRectMake(0, 0, fullSize, fullSize);
    } completion:^(BOOL finished) {
        if (finished) {
            _rippleView.backgroundColor = [UIColor clearColor];
            _rippleView.frame = CGRectMake(_addButton.frame.origin.x, _addButton.frame.origin.y, 56, 56);
            [_rippleView.layer removeAnimationForKey:@"cornerRadius"];
            
            //TODO (Bob): Jump to new view controller here.
            
            [self presentViewController: [PFAddAccountViewController viewControllerFromStoryboard]animated:NO completion:nil];
        }
    }];
}

- (IBAction)didClickMenuButton:(id)sender {
    //Open drawer
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)didClickMoreButton:(id)sender {
    //Pop menu
}

- (IBAction)didClickedKeyboardAction:(id)sender {
    [_lockPasswordField resignFirstResponder];
}

#pragma mark - PFDrawerViewControllerDelegate

- (void)loadAccountsInCategory:(uint64_t)catId {
    
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
    }
}

#pragma mark - Misc

- (void)_initUI {
    //Lock View
    _lockPasswordField.layer.cornerRadius = 20;
    
    //RippleView
    _rippleView.layer.cornerRadius = 28;
    
    //Toolbar
    CALayer *layer = _toolbar.layer;
    layer.shadowOffset = CGSizeMake(0, 2);
    layer.shadowColor = [[UIColor grayColor] CGColor];
    layer.shadowRadius = 1.0;
    layer.shadowOpacity = 1.0;
    
    //TableView
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [_tableView registerNib:[UINib nibWithNibName:@"MainAccountCell" bundle:[NSBundle bundleForClass:self.class]] forCellReuseIdentifier:kMainAccountCellReuseId];
}

- (void)_loadInitCategory {
    _data = [[PFAccountManager sharedManager] fetchRecentUsed:10];
    if (_data.count != 0) {
        [self.tableView reloadData];
    } else {
        //TODO: Show empty view
    }
}

- (void)lockViews {
    if (!_lockView.hidden) {
        //Already locked.
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    _lockView.bounds = [PFResUtil screenSize];
    _lockView.layer.cornerRadius = 0;
    _lockView.hidden = NO;
    [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [self.mm_drawerController closeDrawerAnimated:NO completion:nil];
}

- (void)_dismissLockView {
    if (![self _authorize]) {
        //TODO: Shake it baby.
        return;
    }
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    app.locked = NO;
    
    CGRect screenSize = [PFResUtil screenSize];
    CGFloat fullSize = [PFResUtil screenSize].size.height * 2;
    _lockView.bounds = CGRectMake(0, 0, fullSize, fullSize);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fromValue = [NSNumber numberWithFloat:fullSize / 2];
    animation.toValue = [NSNumber numberWithFloat:0];
    animation.duration = 0.5;
    [_lockView.layer addAnimation:animation forKey:@"cornerRadius"];
    
    [_lockView.layer setCornerRadius:0];

    for (UIView *view in [_lockView subviews]) {
        view.hidden = YES;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        _lockView.bounds = CGRectMake(screenSize.origin.x / 2, screenSize.origin.y / 2, 0, 0);
    } completion:^(BOOL finished) {
        if (finished) {
            _lockView.hidden = YES;
            for (UIView *view in [_lockView subviews]) {
                view.hidden = NO;
            }
            [self _loadInitCategory];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
        }
    }];
}

- (BOOL)_authorize {
    [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    return YES;
}

#pragma mark Test Functions.

- (void)_cryptoTest {
    NSString *rawStr = @"oTNgWmpVF0WqPs8bGB/lop5b/fyI8tP3K2SIyj3V+7L8CAhrtfjnNxqV48VQYqKY";
    
    PFBlowfish *fish = [[PFBlowfish alloc]init];
    
    fish.Key = @"123456";
    fish.IV = @"";
    [fish prepare];
    NSString * result = [fish decrypt:rawStr withMode:modeEBC withPadding:paddingRFC];
    NSLog(@"%@", result);
}

- (void)_encryptTest {
    PFBlowfish *fish = [[PFBlowfish alloc] init];
    fish.Key = @"123456";
    fish.IV = @"";
    [fish prepare];
    NSString *result = [fish encrypt:@"ghgghvg7b0d7bf8-7ac5-4d58-95af-18892b7a712a" withMode:modeEBC withPadding:paddingRFC];
    NSLog(@"%@", result);
}

- (NSString*)_padString:(NSString*)input {
    NSUInteger paddedLength = input.length + (8 - (input.length % 8));
    return [input stringByPaddingToLength:paddedLength withString:@" " startingAtIndex:0];
}

- (void)_coreDataWriteTest {
    PFAccount *acct = [[PFAccount alloc] init];
    acct.name = @"aaaaa";
    acct.category = 1234567;
    PFAccountManager *manager = [PFAccountManager sharedManager];
    [manager saveAccount:acct];
}

- (void)_coreDataReadTest {
    PFAccountManager *manager = [PFAccountManager sharedManager];
    NSArray *accts = [manager fetchAccountsByCategory:1234567];
    return;
}

@end
