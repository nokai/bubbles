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

@implementation NSData (Bubbles)

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

@implementation NSURL (Bubbles)
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (NSURL *)iOSDocumentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)iOSDocumentsDirectoryPath {
    return [[[NSURL iOSDocumentsDirectoryURL] path] stringByAppendingString:@"/"];
}

#elif TARGET_OS_MAC
#endif

- (NSURL *)URLWithRemoteChangedToLocal {
    NSString *currentFileName = [[self URLByDeletingPathExtension].lastPathComponent stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@.%@", 
                                            [NSURL iOSDocumentsDirectoryURL], 
                                            currentFileName, 
                                            [[self pathExtension] lowercaseString]]];
#elif TARGET_OS_MAC
    NSURL *defaultURL = [[NSUserDefaults standardUserDefaults] URLForKey:kUserDefaultMacSavingPath];
    
    // DW: Mac do not use ".xxx" files, remove the first "."
    if ([currentFileName hasPrefix:@"."]) {
        currentFileName = [currentFileName stringByReplacingCharactersInRange:NSRangeFromString(@"0 1") withString:@""];
    }
    
    NSURL *storeURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@%@.%@", 
                        [defaultURL absoluteString], 
                        currentFileName, 
                        [[self pathExtension] lowercaseString]]];
#endif
    return storeURL;
}

// DW: a good convert from remot URL to local one
// or good convert from local to new local
- (NSURL *)URLWithoutNameConflict {
    NSString *originalFileName = [[self URLByDeletingPathExtension].lastPathComponent stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *currentFileName = originalFileName;
    NSInteger currentFileNamePostfix = 2;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@.%@", 
                                            [NSURL iOSDocumentsDirectoryURL], 
                                            currentFileName, 
                                            [self pathExtension]]];
    while ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        DLog(@"AsyncSocketDelegate onSocketDidDisconnect iOS storeURL %i %@", 
             currentFileNamePostfix, 
             storeURL);
        currentFileName = [NSString stringWithFormat:@"%@%%20%i", originalFileName, currentFileNamePostfix++];
        storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@.%@", currentFileName, [self pathExtension]] 
                          relativeToURL:[self URLByDeletingLastPathComponent]];
    }
#elif TARGET_OS_MAC
    NSURL *defaultURL = [self URLByDeletingLastPathComponent];
    NSURL *storeURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@%@.%@", 
                        [defaultURL absoluteString], 
                        currentFileName, 
                        [[self pathExtension] lowercaseString]]];
    while ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        DLog(@"NSURL URLWithSmartConvertionFromURL Mac storeURL %li %@", 
             currentFileNamePostfix, 
             storeURL);
        currentFileName = [NSString stringWithFormat:@"%@%%20%i", originalFileName, currentFileNamePostfix++];
        storeURL = [NSURL URLWithString:
                    [NSString stringWithFormat:@"%@%@.%@", 
                     [defaultURL absoluteString], 
                     currentFileName, 
                     [[self pathExtension] lowercaseString]]];
    }
#endif
    return storeURL;
}

+ (NSString *)formattedFileSize:(unsigned long long)size {
	NSString *formattedStr = nil;
    if (size == 0) 
		formattedStr = @"Empty";
	else 
		if (size > 0 && size < 1024) 
			formattedStr = [NSString stringWithFormat:@"%qu bytes", size];
        else 
            if (size >= 1024 && size < pow(1024, 2)) 
                formattedStr = [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
            else 
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedStr = [NSString stringWithFormat:@"%.2f MB", (size / pow(1024, 2))];
                else 
                    if (size >= pow(1024, 3)) 
                        formattedStr = [NSString stringWithFormat:@"%.3f GB", (size / pow(1024, 3))];
	
	return formattedStr;
}

@end

@implementation WDBubble
@synthesize service = _service;
@synthesize servicesFound = _servicesFound;
@synthesize delegate;
//@synthesize percentageIndicator = _percentageIndicator;

#pragma mark - Private Methods

- (void)dealloc {
    
}

- (void)resolveService:(NSNetService *)s {
    s.delegate = self;
    [s resolveWithTimeout:0];
}

- (void)connectService:(NSNetService *)s {
    //const void *d = [[sender.addresses objectAtIndex:0] bytes];
    //const struct sockaddr_in *a = (const struct sockaddr_in *)d;
    if (s.addresses.count <= 0)
        return;
    
    NSData *t = [s.addresses objectAtIndex:0];
    DLog(@"WDBubble connectService %@ addr %@:%i", s, [t host], [t port]);
    
    // 20120115 DW: isConnected is always not reliable, do not use it
    AsyncSocket *sc = [[AsyncSocket alloc] init];
    sc.delegate = self;
    [sc connectToHost:[t host] onPort:[t port] error:nil];
    [_socketsConnect addObject:sc];
    [sc release];
}

- (void)timerCheckProgress:(NSTimer*)theTimer {
    _pertangeIndicatior = [_socketReceive progressOfReadReturningTag:nil bytesDone:nil total:nil];
    //DLog(@"percent is %f",_pertangeIndicatior);
    if (_pertangeIndicatior == 1.0) {
        [_timer invalidate];
        [_timer release];
        _timer = nil;
    }
}

#pragma mark - Publice Methods

- (id)init {
    if (self = [super init]) {
        DLog(@"WDBubble initSocket");
        
        _currentMessage = nil;
        _dataBuffer = nil;
        
        // DW: accepts connections, creates new sockets to connect incoming sockets.
        _socketListen = [[AsyncSocket alloc] init];
        _socketListen.delegate = self;
        [_socketListen acceptOnPort:0 error:nil];
        
        // DW: connect to remote sockets (which are created by remote's "socketListen") and send them data.
        // Following sockets like it will become temp vars
        //self.socketConnect = [[AsyncSocket alloc] init];
        //self.socketConnect.delegate = self;
        _socketsConnect = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)publishServiceWithPassword:(NSString *)pwd {
    DLog(@"WDBubble publishService <%@>%@ port %i", _service.name, _socketListen, _socketListen.localPort);
    if ([pwd isEqualToString:@""]) {
        _netServiceType = kWDBubbleWebServiceType;
    } else {
        _netServiceType = [NSString stringWithFormat:@"_bubbles_%@._tcp.", pwd];
    }
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    _service = [[NSNetService alloc] initWithDomain:@""
                                               type:_netServiceType
                                               name:[[UIDevice currentDevice] name]
                                               port:_socketListen.localPort];
#elif TARGET_OS_MAC
    _service = [[NSNetService alloc] initWithDomain:@""
                                               type:_netServiceType
                                               name:[[NSHost currentHost] localizedName]
                                               port:_socketListen.localPort];
#endif
    
    _service.delegate = self;
    [_service publish];
}

- (void)browseServices {
    _servicesFound = [[NSMutableArray alloc] init];
    DLog(@"WDBubble browseServices");
    _browser = [[NSNetServiceBrowser alloc] init];
    _browser.delegate = self;
    [_browser searchForServicesOfType:_netServiceType inDomain:kWDBubbleInitialDomain];
    
    // 20120116 DW: it's not possible to find extra domains, give up
    //[_browser searchForBrowsableDomains];
}

- (void)broadcastMessage:(WDMessage *)msg {
    _currentMessage = [msg retain];
    
    // DW: timer
    _timer = [[NSTimer scheduledTimerWithTimeInterval:-1 target:self selector:@selector(timerCheckProgress:) userInfo:nil repeats:YES] retain];
    //[_timer fire];
    
    for (NSNetService *s in self.servicesFound) {
        if ([s.name isEqualToString:_service.name]) {
            continue;
        }
        
        if (s.addresses.count > 0) {
            [self connectService:s];
        } else {
            [self resolveService:s];
        }
    }
}

- (void)stopService {
    [_service stop];
    [_service release];
    _service = nil;
    
    _netServiceType = nil;
}

#pragma mark NSNetServiceDelegate

// Publish

- (void)netServiceWillPublish:(NSNetService *)sender {
    //DLog(@"NSNetServiceDelegate netServiceWillPublish");
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    DLog(@"NSNetServiceDelegate netServiceDidPublish %@", sender);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    DLog(@"NSNetServiceDelegate netService didNotPublish code: %@, domain: %@.", 
         [errorDict objectForKey:NSNetServicesErrorCode], 
         [errorDict objectForKey:NSNetServicesErrorDomain]);
}

// Resolve

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    //[self connectService:sender];
    [self connectService:sender];
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
    
    // DW: we append and write data to file
    //[_dataBuffer appendData:data];
    
    
    [sock readDataToLength:[data length] withTimeout:-1 buffer:nil bufferOffset:0 tag:20];
    [sock readDataWithTimeout:kWDBubbleTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    DLog(@"AsyncSocketDelegate willDisconnectWithError %@: %@", sock, err);
    [sock readDataWithTimeout:kWDBubbleTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    //DLog(@"AsyncSocketDelegate didConnectToHost %@ (l%@)", sock, _socketListen);
    
    // DW: after connected, "socketSender" will send data.
    //AsyncSocket *sc = [_socketsConnect objectAtIndex:0];
    //DLog(@"AsyncSocketDelegate didConnectToHost IP %@ : %@", sock.localHost, sc.localHost);
    //if ([sock.localHost isEqualToString:sc.localHost]) {
    if (_socketsConnect.count > 0) {
        // DW: a sender
        
        //NSData *t = [NSKeyedArchiver archivedDataWithRootObject:_currentMessage];
        //[sock writeData:t withTimeout:kWDBubbleTimeOut tag:0];
        //DLog(@"AsyncSocketDelegate didConnectToHost writing %@", t);
        
        _streamFileReader = [[NSInputStream alloc] initWithFileAtPath:_currentMessage.fileURL.path];
        [_streamFileReader setDelegate:self];
        [_streamFileReader scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
        [_streamFileReader open];
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
        
        WDMessage *t = nil;
        @try {
            [_dataBuffer writeToFile:@"dataBuffer" atomically:YES];
            t = [NSKeyedUnarchiver unarchiveObjectWithData:_dataBuffer];
        }
        @catch (NSException *exception) {
            DLog(@"AsyncSocketDelegate onSocketDidDisconnect @catch %@", exception);
            // DW: clean up
            [_dataBuffer release];
            _dataBuffer = nil;
        }
        @finally {
            DLog(@"AsyncSocketDelegate onSocketDidDisconnect @finally");
            if ((!t)||(!_dataBuffer))
                return;
            
            if (t.type == WDMessageTypeText) {
                [self.delegate didReceiveMessage:t ofText:[[NSString alloc] initWithData:t.content encoding:NSUTF8StringEncoding]];
            } else if (t.type == WDMessageTypeFile) {
                NSURL *storeURL = [[t.fileURL URLWithRemoteChangedToLocal] URLWithoutNameConflict];
                DLog(@"WDBubble onSocketDidDisconnect %@", storeURL.pathExtension);
                [t.content writeToURL:storeURL atomically:YES];
                [self.delegate didReceiveMessage:t ofFile:storeURL];
            }
            
            // DW: clean up
            //[t release];
            [_dataBuffer release];
            _dataBuffer = nil;
        }
    } else {
        [_socketsConnect removeObject:sock];
    }
    
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    if (![netService.domain isEqualToString:@"local."]) {
        return;
    }
    
    if ([_servicesFound indexOfObject:netService] != NSNotFound) {
        return;
    }
    
    // DW: "_servicesFound" always contains "self"'s service, this helps to show a list of all peers.
    [_servicesFound addObject:netService];
    DLog(@"NSNetServiceBrowserDelegate didFindService %@", self.servicesFound);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWDBubbleNotificationServiceUpdated object:nil];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)netService moreComing:(BOOL)moreComing {
	[_servicesFound removeObject:netService];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWDBubbleNotificationServiceUpdated object:nil];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    DLog(@"NSNetServiceBrowserDelegate didFindDomain %@", domainName);
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
        case NSStreamEventHasBytesAvailable: {
            if(!_streamDataBufferReader) {
                _streamDataBufferReader = [[NSMutableData data] retain];
            }
            uint8_t buf[1024];
            unsigned int len = 0;
            
            // DW: we have different conversions between Mac and iOS
            len = [(NSInputStream *)theStream read:buf maxLength:1024];
            if(len) {
                [_streamDataBufferReader appendBytes:(const void *)buf length:len];
                // _streamBytesRead is an instance variable of type NSNumber.
                //[_streamBytesRead setIntValue:[_streamBytesRead intValue]+len];
                _streamBytesRead = _streamBytesRead+len;
                
                // DW: now we send these read data
            } else {
                NSLog(@"no buffer!");
            }
            break;
        } case NSStreamEventEndEncountered: {
            [_streamFileReader close];
            [_streamFileReader removeFromRunLoop:[NSRunLoop currentRunLoop]
                                         forMode:NSDefaultRunLoopMode];
            [_streamFileReader release];
            _streamFileReader = nil; // stream is ivar, so reinit it
            break;
        } default: {
        }
    }
}

@end
