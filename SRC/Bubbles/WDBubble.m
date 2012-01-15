//
//  WDBubble.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "WDBubble.h"
#include <ifaddrs.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation NSData (Additions)

- (int)port {
    int port;
    struct sockaddr *addr;
    
    addr = (struct sockaddr *)[self bytes];
    if (addr->sa_family == AF_INET)
        // IPv4 family
        port = ntohs(((struct sockaddr_in *)addr)->sin_port);
    else if (addr->sa_family == AF_INET6)
        // IPv6 family
        port = ntohs(((struct sockaddr_in6 *)addr)->sin6_port);
    else
        // The family is neither IPv4 nor IPv6. Can't handle.
        port = 0;
    
    return port;
}


- (NSString *)host {
    struct sockaddr *addr = (struct sockaddr *)[self bytes];
    if (addr->sa_family == AF_INET) {
        char *address = inet_ntoa(((struct sockaddr_in *)addr)->sin_addr);
        if (address)
            return [NSString stringWithCString:address encoding:NSUTF8StringEncoding];
    } else if (addr->sa_family == AF_INET6) {
        struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)addr;
        char straddr[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(addr6->sin6_addr), straddr, sizeof(straddr));
        return [NSString stringWithCString:straddr encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end

@implementation WDBubble
@synthesize service, browser, netServiceType;
@synthesize socketListen, servicesFound = _servicesFound;
@synthesize delegate;
@synthesize percentageIndicator = _percentageIndicator;

#pragma mark - Private Methods

- (NSString *)getIPAddress { 
    
    NSString *address = @"error"; 
    struct ifaddrs *interfaces = NULL; 
    struct ifaddrs *temp_addr = NULL; 
    int success = 0; 
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces); 
    
    if (success == 0) { 
        // Loop through linked list of interfaces 
        
        temp_addr = interfaces; 
        while(temp_addr != NULL) { 
            
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) { 
                    // Get NSString from C String 
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; 
                } 
            }
            
            temp_addr = temp_addr->ifa_next; 
        }
    } 
    
    // Free memory 
    freeifaddrs(interfaces);
    return address;
}

- (void)resolveService:(NSNetService *)s {
    s.delegate = self;
    [s resolveWithTimeout:0];
}

- (void)connectService:(NSNetService *)s {
    //const void *d = [[sender.addresses objectAtIndex:0] bytes];
    //const struct sockaddr_in *a = (const struct sockaddr_in *)d;
    NSData *t = [s.addresses objectAtIndex:0];
    DLog(@"WDBubble connectService %@ addr %@:%i", s, [t host], [t port]);
    
    // 20120115 DW: isConnected is always not reliable, do not use it
    AsyncSocket *sc = [[AsyncSocket alloc] init];
    sc.delegate = self;
    [sc connectToHost:[t host] onPort:[t port] error:nil];
    [_socketConnect addObject:sc];
    [sc release];
}

- (void)timerCheckProgress:(NSTimer*)theTimer {
    _pertangeIndicatior = [_socketReceive progressOfReadReturningTag:nil bytesDone:nil total:nil];
    DLog(@"percent is %f",_pertangeIndicatior);
    if (_pertangeIndicatior == 1.0) {
        [_timer invalidate];
        [_timer release];
        _timer = nil;
    }
}

#pragma mark - Publice Methods

- (void)initSocket {
    DLog(@"WDBubble initSocket");
    
    _currentMessage = nil;
    _dataBuffer = nil;
    
    // DW: accepts connections, creates new sockets to connect incoming sockets.
    self.socketListen = [[AsyncSocket alloc] init];
    self.socketListen.delegate = self;
    [self.socketListen acceptOnPort:0 error:nil];
    
    // DW: connect to remote sockets (which are created by remote's "socketListen") and send them data.
    // Following sockets like it will become temp vars
    //self.socketConnect = [[AsyncSocket alloc] init];
    //self.socketConnect.delegate = self;
    _socketConnect = [[NSMutableArray alloc] init];
}

- (void)publishServiceWithPassword:(NSString *)pwd {
    DLog(@"WDBubble publishService <%@>%@ port %i", self.service.name, self.socketListen, self.socketListen.localPort);
    if ([pwd isEqualToString:@""]) {
        self.netServiceType = kWDBubbleWebServiceType;
    } else {
        self.netServiceType = [NSString stringWithFormat:@"_bubbles_%@._tcp.", pwd];
    }
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    self.service = [[NSNetService alloc] initWithDomain:@""
                                                   type:self.netServiceType
                                                   name:[[UIDevice currentDevice] name]
                                                   port:self.socketListen.localPort];
#elif TARGET_OS_MAC
    self.service = [[NSNetService alloc] initWithDomain:@""
                                                   type:self.netServiceType
                                                   name:[[NSHost currentHost] localizedName]
                                                   port:self.socketListen.localPort];
#endif
    
    self.service.delegate = self;
    [self.service publish];
}

- (void)browseServices {
    _servicesFound = [[NSMutableArray alloc] init];
    DLog(@"WDBubble browseServices");
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.delegate = self;
    [self.browser searchForServicesOfType:self.netServiceType inDomain:kWDBubbleInitialDomain];
}

- (void)broadcastMessage:(WDMessage *)msg {
    _currentMessage = [msg retain];
    
    // DW: timer
    _timer = [[NSTimer scheduledTimerWithTimeInterval:-1 target:self selector:@selector(timerCheckProgress:) userInfo:nil repeats:YES] retain];
    //[_timer fire];
    
    for (NSNetService *s in self.servicesFound) {
        if ([s.name isEqualToString:self.service.name])
        {
            continue;
        }
        
        if ([s.addresses count] <= 0) {
            [s resolveWithTimeout:0];
        } else {
            [self connectService:s];
        }
    }
}

- (void)stopService {
    [self.service stop];
    [self.service release];
    self.service = nil;
    
    self.netServiceType = nil;
}

#pragma mark NSNetServiceDelegate

// Publish

- (void)netServiceWillPublish:(NSNetService *)sender {
    //DLog(@"NSNetServiceDelegate netServiceWillPublish");
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    //DLog(@"NSNetServiceDelegate netServiceDidPublish %@, %i", self.service, self.service.port);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    DLog(@"NSNetServiceDelegate netService didNotPublish code: %@, domain: %@.", 
         [errorDict objectForKey:NSNetServicesErrorCode], 
         [errorDict objectForKey:NSNetServicesErrorDomain]);
}

// Resolve

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    //[self connectService:sender];
}

#pragma mark AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    DLog(@"AsyncSocketDelegate didAcceptNewSocket %@: %@", sock, newSocket);
    
    // DW: this "newSocket" is connected to remote's "socketSender", use it to read data then.
    // It is the very first place to read data.
    _dataBuffer = [[NSMutableData alloc] init];
    [newSocket readDataWithTimeout:kWDBubbleTimeOut tag:0];
    
    _socketReceive = [newSocket retain];
    //_timer = [[NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(timerCheckProgress:) userInfo:nil repeats:YES] retain];
   // [_timer fire];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //DLog(@"AsyncSocketDelegate didReadData %@: %@", sock, data);
    [_dataBuffer appendData:data];
    
    [sock readDataToLength:[data length] withTimeout:-1 buffer:nil bufferOffset:0 tag:20];
    [sock readDataWithTimeout:kWDBubbleTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    DLog(@"AsyncSocketDelegate willDisconnectWithError %@: %@", sock, err);
    [sock readDataWithTimeout:kWDBubbleTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    //DLog(@"AsyncSocketDelegate didConnectToHost %@ (l%@)", sock, self.socketListen);
    
    // DW: after connected, "socketSender" will send data.
    //AsyncSocket *sc = [_socketConnect objectAtIndex:0];
    //DLog(@"AsyncSocketDelegate didConnectToHost IP %@ : %@", sock.localHost, sc.localHost);
    //if ([sock.localHost isEqualToString:sc.localHost]) {
    if (_socketConnect.count > 0) {
        // DW: a sender
        
        NSData *t = [NSKeyedArchiver archivedDataWithRootObject:_currentMessage];
        [sock writeData:t withTimeout:kWDBubbleTimeOut tag:0];
        //DLog(@"AsyncSocketDelegate didConnectToHost writing %@", t);
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    DLog(@"AsyncSocketDelegate didWriteDataWithTag %@", sock);
    
    // DW: anyone of the two connected sockets call "disconnect" will disconnect the connection. XD
    [sock disconnectAfterWriting];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    DLog(@"AsyncSocketDelegate onSocketDidDisconnect %@", sock);
    if (_dataBuffer != nil) {
        // DW: a receive socket
        
        WDMessage *t = [NSKeyedUnarchiver unarchiveObjectWithData:_dataBuffer];
        if (t.type == WDMessageTypeText) {
            [self.delegate didReceiveText:[[NSString alloc] initWithData:t.content encoding:NSUTF8StringEncoding]];
        } else if (t.type == WDMessageTypeImage) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            UIImage *ti = [[UIImage alloc] initWithData:t.content];
#elif TARGET_OS_MAC
            NSImage *ti = [[NSImage alloc] initWithData:t.content];
#endif       
            [self.delegate didReceiveImage:ti];
        }
       
        // DW: clean up
        [_dataBuffer release];
        _dataBuffer = nil;
    } else {
        [_socketConnect removeObject:sock];
    }
    
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    if ([_servicesFound indexOfObject:netService] != NSNotFound) {
        return;
    }
    
    // DW: "_servicesFound" always contains "self"'s service, this helps to show a list of all peers.
    [_servicesFound addObject:netService];
    DLog(@"NSNetServiceBrowserDelegate didFindService %@", self.servicesFound);
    if (![netService.name isEqualToString:self.service.name]) {
        DLog(@"NSNetServiceBrowserDelegate didFindService resolve %@ : %@", netService.name, self.service.name);
        [self resolveService:netService];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWDBubbleNotification object:nil];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing {
	[_servicesFound removeObject:netService];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWDBubbleNotification object:nil];
}

@end
