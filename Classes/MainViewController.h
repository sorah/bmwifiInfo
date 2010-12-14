//
//  MainViewController.h
//  bmwifiInfo
//
//  Created by Shota Fukumori on 12/13/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "RegexKitLite.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	IBOutlet UILabel *labelBattery;
	IBOutlet UILabel *labelLevel;
	IBOutlet UILabel *labelCarrier;
	IBOutlet UILabel *labelNetwork;
	IBOutlet UILabel *labelStatus;
	NSUserDefaults *pref;
}

-(IBAction)showInfo:(id)sender;
-(BOOL) isBwAvailable;
-(BOOL) login;
-(NSMutableDictionary*) getInformation;
-(IBAction)reloadInformation: (id) sender;


@end
