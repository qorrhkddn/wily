#import "CachingAVPlayerItem.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface CachingAVPlayerItem () <AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, readonly) NSMutableArray *pendingRequests;

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation CachingAVPlayerItem

- (instancetype)initWithURL:(NSURL *)URL {
  _pendingRequests = [NSMutableArray array];

  AVURLAsset *asset = [CachingAVPlayerItem assetForURL:URL];
  [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
  return [super initWithAsset:asset];
}

+ (AVURLAsset *)assetForURL:(NSURL *)URL {
  NSURL *customURL = [CachingAVPlayerItem customURLForURL:URL];
  return [AVURLAsset URLAssetWithURL:customURL options:nil];
}

+ (NSURL *)customURLForURL:(NSURL *)URL {
  return [NSURL URLWithString:
          [NSStringFromClass(self) stringByAppendingString:URL.absoluteString]];
}

+ (NSURL *)URLfromCustomURL:(NSURL *)customURL {
  return [NSURL URLWithString:
          [customURL.absoluteString substringFromIndex:[NSStringFromClass(self) length]]];
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  self.receivedData = [NSMutableData data];
  self.response = (NSHTTPURLResponse *)response;

  [self processPendingRequests];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self.receivedData appendData:data];

  [self processPendingRequests];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [self processPendingRequests];

  NSString *cachedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cached.mp3"];

  [self.receivedData writeToFile:cachedFilePath atomically:YES];
}

#pragma mark - AVURLAsset resource loading

- (void)processPendingRequests {
  NSMutableArray *requestsCompleted = [NSMutableArray array];

  for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
    [self fillInContentInformation:loadingRequest.contentInformationRequest];

    BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];

    if (didRespondCompletely) {
      [requestsCompleted addObject:loadingRequest];

      [loadingRequest finishLoading];
    }
  }

  [self.pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest {
  if (contentInformationRequest == nil || self.response == nil) {
    return;
  }

  NSString *mimeType = [self.response MIMEType];
  CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);

  contentInformationRequest.byteRangeAccessSupported = YES;
  contentInformationRequest.contentType = CFBridgingRelease(contentType);
  contentInformationRequest.contentLength = [self.response expectedContentLength];
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest {
  long long startOffset = dataRequest.requestedOffset;
  if (dataRequest.currentOffset != 0)   {
    startOffset = dataRequest.currentOffset;
  }

  // Don't have any data at all for this request
  if (self.receivedData.length < startOffset) {
    return NO;
  }

  // This is the total data we have from startOffset to whatever has been downloaded so far
  NSUInteger unreadBytes = self.receivedData.length - (NSUInteger)startOffset;

  // Respond with whatever is available if we can't satisfy the request fully yet
  NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);

  [dataRequest respondWithData:[self.receivedData subdataWithRange:NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith)]];

  long long endOffset = startOffset + dataRequest.requestedLength;
  BOOL didRespondFully = self.receivedData.length >= endOffset;

  return didRespondFully;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
  if (self.connection == nil) {
    NSURL *interceptedURL = [loadingRequest.request URL];
    NSURL *URL = [CachingAVPlayerItem URLfromCustomURL:interceptedURL];

    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];

    [self.connection start];
  }

  [self.pendingRequests addObject:loadingRequest];

  return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
  [self.pendingRequests removeObject:loadingRequest];
}

@end
