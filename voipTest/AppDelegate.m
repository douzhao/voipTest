//
//  AppDelegate.m
//  voipTest
//
//  Created by Dmitriy on 20.03.15.
//  Copyright (c) 2015 Dmitriy. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()<NSStreamDelegate>

@property (nonatomic) BOOL sentPing;

@end

const uint8_t pingString[] = "ping\n";
const uint8_t pongString[] = "pong\n";

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSLog(@"voip test didFinishLaunchingWithOptions");
  UIUserNotificationType types = UIUserNotificationTypeBadge |
  UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
  
  UIUserNotificationSettings *mySettings =
  [UIUserNotificationSettings settingsForTypes:types categories:nil];
  
  [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
  
  if(self.inputStream)
  {
    [self.inputStream close];
    [self.outputStream close];
    self.inputStream = nil;
    self.outputStream = nil;
  }
  if (!self.inputStream)
  {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(@"192.168.11.108"), 50007, &readStream, &writeStream);
    
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [self.outputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType] ;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
  }
  
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  NSLog(@"voip test WillResignActive");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  
  NSLog(@"voip test DidEnterBackground");
  [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
    uint8_t pingString[] = "ping\n";
    [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
  }];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"voip test BecomeActive");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"voip test WillEnterForeground");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  NSLog(@"voip test WillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    app.applicationIconBadgeNumber = notif.applicationIconBadgeNumber - 1;
    
    notif.soundName = UILocalNotificationDefaultSoundName;
    
    [self showAlert:[NSString stringWithFormat:@"%@",notif.alertBody] withTitle:@"Title"];
    
}

- (void) showAlert:(NSString*)pushmessage withTitle:(NSString*)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:pushmessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
  switch (eventCode) {
    case NSStreamEventNone:
      // do nothing.
      break;
      
    case NSStreamEventEndEncountered:
      [self addEvent:@"Connection Closed"];
      break;
      
    case NSStreamEventErrorOccurred:
      [self addEvent:[NSString stringWithFormat:@"Had error: %@", aStream.streamError]];
      break;
      
    case NSStreamEventHasBytesAvailable:
      if (aStream == self.inputStream)
      {
        uint8_t buffer[1024];
        NSInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
        NSString *stringRead = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
        stringRead = [stringRead stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        [self addEvent:[NSString stringWithFormat:@"Received: %@", stringRead]];
        
        if ([stringRead rangeOfString:@"notify"].location != NSNotFound)
        {
          UILocalNotification *notification = [[UILocalNotification alloc] init];
          notification.alertBody = @"New VOIP call";
          notification.alertAction = @"Answer";
          [self addEvent:@"Notification sent"];
          [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
          
        } if ([stringRead rangeOfString:@"ping"].location != NSNotFound) {
          [self.outputStream write:pongString maxLength:strlen((char*)pongString)];
        }
      }
      break;
      
    case NSStreamEventHasSpaceAvailable:
      if (aStream == self.outputStream && !self.sentPing)
      {
        self.sentPing = YES;
        if (aStream == self.outputStream)
        {
          [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
          [self addEvent:@"Ping sent"];
        }
      }
      break;
      
    case NSStreamEventOpenCompleted:
      if (aStream == self.inputStream)
      {
        [self addEvent:@"Connection Opened"];
      }
      break;
      
    default:
      break;
  }
}

- (void)addEvent:(NSString *)event
{
  NSLog(@"New event: %@", event);
}

@end
