//
//  MainViewController.m
//  bmwifiInfo
//
//  Created by Shota Fukumori on 12/13/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"


@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
	
	pref = [[NSUserDefaults standardUserDefaults] retain];
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:@"192.168.0.1" forKey:@"ip"];
	[defaultValues setObject:@"admin" forKey:@"user"];
	[defaultValues setObject:@"admin" forKey:@"pass"];
	[pref registerDefaults:defaultValues];
	
	[self reloadInformation:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reloadInformation:nil];
}



- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}



- (BOOL) isBwAvailable {
	NSMutableURLRequest *req;
	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	
	req = [[NSMutableURLRequest alloc]
		   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/",
											 [pref stringForKey:@"ip"]]]];
	req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	[req setHTTPMethod:@"HEAD"];
	
	[NSURLConnection sendSynchronousRequest:req
						  returningResponse:&res
									  error:&err];
	
	BOOL ny = NO;
	NSLog(@"%@", err);
	if(!err && [@"GoAhead-Webs" isEqualToString:[[res allHeaderFields] objectForKey:@"Server"]])
		ny = YES;
	[req release];
	return ny;
}

- (BOOL) login {
	NSMutableURLRequest *req;
	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	NSData *result = nil;
	
	req = [[NSMutableURLRequest alloc] 
		   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/goform/login",
											 [pref stringForKey:@"ip"]]]];
	req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[[NSString stringWithFormat:@"user=%@&psw=%@",
					   [pref stringForKey:@"user"],[pref stringForKey:@"pass"]]
					  dataUsingEncoding:NSUTF8StringEncoding]];
	
	result = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	
	[req release];
	
	if(err) {
		NSLog(@"error = %@",err);
	}else{
		NSString *str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
		if([str isMatchedByRegex:@"login.asp"]) {
			[str release];
			return NO;
		}
		[str release];
	}
	return YES;
}

- (NSMutableDictionary*) getInformation {
	NSMutableDictionary *hash = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  @"Bm-wifi is missing",@"wanState",@"",@"network_type",
								  @"--",@"network_provider",@"--",@"battery_status",
								  @"--",@"rssi",nil] retain];
	if([self isBwAvailable]){
		if(![self login]) {
			[hash release];
			return [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"Failed to Login",@"wanState",@"",@"network_type",
					@"--",@"network_provider",@"--",@"battery_status",
					@"--",@"rssi",nil];
		}
		NSMutableURLRequest *req;
		NSHTTPURLResponse *res = nil;
		NSError *err = nil;
		NSData *result;
		NSString *result_string;
		
		req = [[NSMutableURLRequest alloc]
			   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/logo.asp",
												 [pref stringForKey:@"ip"]]]];
		req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
		[req setHTTPMethod:@"GET"];
		
		result = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		
		if(!err){
			result_string = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
			[hash release];
			hash = [[NSMutableDictionary alloc] init];
			NSArray *ary = [[result_string componentsSeparatedByRegex:
							 @"var rssi = '(.+?)'; \nvar wanState = '(.+?)';  \nvar icardState = '.+?';\nvar network_type = '(.+?)';\nvar network_provider = '(.+?)';\nvar roam_status = '.+?';\nvar battery_status = '(.+?)';"
							 ] retain];
			[result_string release];
			[hash setObject:[ary objectAtIndex:1]
					 forKey:@"rssi"];
			[hash setObject:[ary objectAtIndex:2]
					 forKey:@"wanState"];
			[hash setObject:[ary objectAtIndex:3]
					 forKey:@"network_type"];
			[hash setObject:[ary objectAtIndex:4]
					 forKey:@"network_provider"];
			[hash setObject:[ary objectAtIndex:5]
					 forKey:@"battery_status"];
			if(ary) [ary release];
		}
		[req release];
	}
	return [hash autorelease];
}

-(IBAction) reloadInformation: (id)sender {
	if([[pref stringForKey:@"ip"] isEqualToString:@"192.168.0.1"] &&
	   [[pref stringForKey:@"user"] isEqualToString:@"admin"] &&
	   [[pref stringForKey:@"pass"] isEqualToString:@"admin"] && ![self login]) {
		UIAlertView *alert =   [[UIAlertView alloc]
								initWithTitle:@"Please check settings."
								message:@"Please check settings from \"Settings\" > \"Bm-wifi Info\" on home screen."
								delegate:nil
								cancelButtonTitle:nil
								otherButtonTitles:@"OK", nil
								];
		[alert show];
		[alert release];
	}
	NSDictionary *status = [[self getInformation] retain];
	
	[labelStatus setText:[status valueForKey:@"wanState"]];
	[labelNetwork setText:[status valueForKey:@"network_type"]];
	[labelCarrier setText:[status valueForKey:@"network_provider"]];
	[labelBattery setText:[NSString stringWithFormat:@"%@%%",
						   [status valueForKey:@"battery_status"]]];
	
	[labelLevel setText:[NSString stringWithFormat:@"%@",
						 [status valueForKey:@"rssi"]]];
	
	if([self isBwAvailable] && ![[status valueForKey:@"wanState"] isEqualToString:@"Failed to Login"]) {
		NSInteger rssi = [[status valueForKey:@"rssi"] integerValue];
		NSInteger state = 0;
		if ( rssi > 107 || rssi < 1 ) {
			state = 0;
		} else if ( rssi <= 107 && rssi >  99 ) {
			state = 1;
		} else if ( rssi <= 99  && rssi >  93 ) {
			state = 2;
		} else if ( rssi <= 93  && rssi >  87 ) {
			state = 3;
		} else if ( rssi <= 87  && rssi >  81 ) {
			state = 4;
		} else if ( rssi <= 81  && rssi >= 1  ) {
			state = 5;
		}
		[labelLevel setText:[NSString stringWithFormat:@"%d (%@)",
							 state,[status valueForKey:@"rssi"]]];
	}
	[status autorelease];
}





- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[pref synchronize];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc {
	[pref release];
	[labelBattery release];
	[labelLevel release];
	[labelCarrier release];
	[labelNetwork release];
	[labelStatus release];	
    [super dealloc];
}


@end
