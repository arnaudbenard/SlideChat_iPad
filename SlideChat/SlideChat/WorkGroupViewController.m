//
//  WorkGroupViewController.m
//  SlideTime
//
//  Created by Frederic Jacobs on 11/8/12.
//  Copyright (c) 2012 Movies.io Inc. All rights reserved.
//

#import "WorkGroupViewController.h"
#import "SCSync.h"
#import "ChatWindowFactory.h"
#import "CGPointUtils.h"
#import "DocumentViewController.h"

@interface WorkGroupViewController ()

@end

@implementation WorkGroupViewController
@synthesize usersAndFiles;


static NSString* const kApiKey = @"17075832";
static NSString* const kToken = @"devtoken";
static const NSString * BOX_API_KEY = @"x0dcfl3a1vjc56j0sg6cytjfm3dt5r05";


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        documents = @[ @"" ];
        users = @[ @"Fred",@"Arnaud", @"Peter", @"Reid", @"David", @"Jack" ];
        subscribersFeedViews = [NSMutableArray array];
    }
    return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 2;
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section == 0) {
        return @"Buddies";
    }
    
    if (section == 1) {
        return @"Docs";
    }
    
    else return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
        
    if (section == 0) {
        return [subscribersFeedViews count];
    }
    
    else {
        return [documents count];
    }
        
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = [users objectAtIndex:indexPath.row];
    }
    
    if (indexPath.section == 1) {
        cell.textLabel.text = [documents objectAtIndex:indexPath.row];
    }
    
    return cell;
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    ot_session = [[OTSession alloc] initWithSessionId:self.kSessionIdea delegate:self];
    
    [self doConnect];
}

#pragma OpenTok

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage = [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    [self showAlert:alertMessage];
}


- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
    [subscribersFeedViews addObject:[[OTSubscriber alloc]initWithStream:stream delegate:self]];
    [self redrawView];
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream{

    NSLog(@"session didDropStream (%@)", stream.streamId);

    for (int i = 0; i < [subscribersFeedViews count]; i++) {
    
        OTSubscriber *subscribers = [subscribersFeedViews objectAtIndex:i];
        if([subscribers.stream.streamId isEqualToString:stream.streamId]){
            [subscribersFeedViews removeObjectAtIndex:i];
            [self redrawView];
            return;
        }
    }

}

- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{

}

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error {
    NSLog(@"publisher didFailWithError %@", error);
    [self showAlert:[NSString stringWithFormat:@"There was an error publishing."]];
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
    [self showAlert:[NSString stringWithFormat:@"There was an error subscribing to stream %@", subscriber.stream.streamId]];
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    NSLog(@"sessionDidFail");
    [self showAlert:[NSString stringWithFormat:@"There was an error connecting to session %@", session.sessionId]];
}

- (void)doPublish
{
    ot_publisher = [[OTPublisher alloc] initWithDelegate:self];
    [ot_publisher setName:[[SCSync sharedManager] username]];
    [ot_session publish:ot_publisher];
}

- (void)doConnect
{
    [ot_session connectWithApiKey:kApiKey token:kToken];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)showAlert:(NSString*)string {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                    message:string
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}



- (void) redrawView {
    
    for (int i = 0; i < [subscribersFeedViews count]; i++) {
        
        NSLog(@"Array size :%i Index : %i",[subscribersFeedViews count],i);
        
        OTSubscriber *subscriber = [subscribersFeedViews objectAtIndex:i];
   
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.5];
        subscriber.view.frame = [ChatWindowFactory windowFactoryForXPeerConnections:([subscribersFeedViews count]-1) mode:2 andView:i];
         [self.view addSubview:subscriber.view];
    }
    [UIView commitAnimations];
    
    if ([ChatWindowFactory tableViewIsVisibleForPeers:[subscribersFeedViews count]]){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.5];
        [usersAndFiles setHidden:FALSE];
        if (presentation != nil) {
            [presentation removeFromSuperview];
            presentation = nil;
        }
        [UIView commitAnimations];
    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.5];
        [usersAndFiles setHidden:TRUE];
        [UIView commitAnimations];
        if (presentation == nil) {
            presentation = [[UIButton alloc]init];
            [presentation setImage:[UIImage imageNamed:@"icon.png"] forState:UIControlStateNormal];
            presentation.frame = CGRectMake(899, 707, 72, 72);
            [self.view addSubview:presentation];
        }
    }
    
    [self.usersAndFiles reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if([touches count] == 2){
        NSArray *twoTouches = [touches allObjects];
        UITouch *first = [twoTouches objectAtIndex:0];
        UITouch *second = [twoTouches objectAtIndex:1];
        initialDistance = distanceBetweenPoints([first locationInView: self.view],[second locationInView:self.view]);
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if([touches count] == 2)
    {
        NSArray *twoTouches = [touches allObjects];
        UITouch *first = [twoTouches objectAtIndex:0];
        UITouch *second = [twoTouches objectAtIndex:1];
        CGFloat currentDistance = distanceBetweenPoints(
                                                        [first locationInView: self.view],
                                                        [second locationInView:self.view]);
        
        if(initialDistance == 0)
            initialDistance = currentDistance;
        else if (currentDistance - initialDistance >kMinimumPinchDelta){
            [self performSelector:@selector(eraselabel)
                       withObject:nil
                       afterDelay:0];
        }
        
        else if(initialDistance - currentDistance >kMinimumPinchDelta){
                [self performSelector:@selector(eraselabel)
                       withObject:nil
                       afterDelay:0];
            
        }
    }
}

- (void) eraselabel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    initialDistance = 0;
    
    
}

@end
