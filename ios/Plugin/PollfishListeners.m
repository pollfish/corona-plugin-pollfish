#import "PollfishListeners.h"
#import "PollfishPlugin.h"

@implementation PollfishListeners


#pragma mark - Corona functions


-(void) setLuaState: (lua_State*) newState andLuaRef: (CoronaLuaRef) newRef
{
    luaRef = newRef;
    L= newState;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // set observers for Pollfish notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyCompleted:)
                                                 name:@"PollfishSurveyCompleted" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyOpened:)
                                                 name:@"PollfishOpened" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyClosed:)
                                                 name:@"PollfishClosed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyReceived:)
                                                 name:@"PollfishSurveyReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyNotAvailable:)
                                                 name:@"PollfishSurveyNotAvailable" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userNotEligible:)
                                                 name:@"PollfishUserNotEligible" object:nil];
}


-(void) sendEvent: (NSString*) eventName;
{
    NSLog(@"Sending Event: %@", eventName);
    
    // Create event and add message to it
    
    CoronaLuaNewEvent( L, "pluginlibraryevent" );
    lua_pushstring( L, [eventName UTF8String] );
    lua_setfield( L, -2, "phase" );
    
    // Dispatch event to library's listener
    
    CoronaLuaDispatchEvent( L, luaRef, 0 );
}

#pragma mark - Pollfish notification functions

- (void)surveyCompleted:(NSNotification *)notification
{
    NSLog(@"Pollfish - surveyCompleted");
    
    [ self sendEvent:@"onPollfishSurveyCompleted"];
}

- (void)surveyOpened:(NSNotification *)notification
{
    NSLog(@"Pollfish - surveyOpened");
    
    [ self sendEvent:@"onPollfishOpened"];
}

- (void)surveyClosed:(NSNotification *)notification
{
    NSLog(@"Pollfish - surveyClosed");
    
    [ self sendEvent:@"onPollfishClosed"];
}

- (void)surveyReceived:(NSNotification *)notification
{
    NSLog(@"Pollfish - surveyReceived");
    
    [ self sendEvent:@"onPollfishSurveyReceived"];
}

- (void)userNotEligible:(NSNotification *)notification
{
    NSLog(@"Pollfish - userNotEligible");
    
    [ self sendEvent:@"onUserNotEligible"];
    
}

- (void)surveyNotAvailable:(NSNotification *)notification
{
    NSLog(@"Pollfish - surveyNotAvailable");
    
    [ self sendEvent:@"onPollfishSurveyNotAvailable"];
}


@end
