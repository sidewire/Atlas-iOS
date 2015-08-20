//
//  ATLMediaAttachmentTests.m
//  Atlas
//
//  Created by Klemen Verdnik on 2/26/15.
//  Copyright (c) 2015 Layer, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ATLMediaAttachment.h"
#import "ATLTestUtilities.h"
#import "ATLMediaInputStream.h"

#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>

@interface ATLMediaAttachmentTests : XCTestCase

@end

@implementation ATLMediaAttachmentTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testMediaAttachmentInitFailures
{
    expect(^{
        __unused ATLMediaAttachment *mediaAttachment = [[ATLMediaAttachment alloc] init];
    }).to.raiseWithReason(NSInternalInconsistencyException, @"Failed to call designated initializer. Use one of the following initialiers: mediaAttachmentWithAssetURL:thumbnailSize:, mediaAttachmentWithImage:metadata:thumbnailSize:, mediaAttachmentWithText:, mediaAttachmentWithLocation:");
    
    expect(^{
        __unused ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithAssetURL:nil thumbnailSize:0];
    }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot initialize ATLMediaAttachment with `nil` assetURL.");

    expect(^{
        __unused ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithImage:nil metadata:nil thumbnailSize:0];
    }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot initialize ATLMediaAttachment with `nil` image.");

    expect(^{
        __unused ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithText:nil];
    }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot initialize ATLMediaAttachment with `nil` text.");

    expect(^{
        __unused ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithLocation:nil];
    }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot initialize ATLMediaAttachment with `nil` location.");
}

- (void)testMediaAttachmentWithText
{
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithText:@"What about the Noodle Incident?"];
    
    // Verifying properties
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLTextMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"What about the Noodle Incident?");
    expect(mediaAttachment.thumbnailSize).to.equal(0);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"text/plain");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.beNil();
    expect(mediaAttachment.thumbnailInputStream).to.beNil();
    expect(mediaAttachment.metadataMIMEType).to.beNil();
    expect(mediaAttachment.metadataInputStream).to.beNil();
    
    // Verifying stream content
    NSData *payload = ATLTestAttachmentDataFromStream(mediaAttachment.mediaInputStream);
    expect(payload).toNot.beNil();
    expect(payload).to.equal([@"What about the Noodle Incident?" dataUsingEncoding:NSUTF8StringEncoding]);
}

- (void)testMediaAttachmentWithLocation
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:46.368383 longitude:15.106631];
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithLocation:location];
    
    // Verifying properties
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLLocationMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Location");
    expect(mediaAttachment.thumbnailSize).to.equal(0);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"location/coordinate");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.beNil();
    expect(mediaAttachment.thumbnailInputStream).to.beNil();
    expect(mediaAttachment.metadataMIMEType).to.beNil();
    expect(mediaAttachment.metadataInputStream).to.beNil();
    
    // Verifying stream content
    NSData *payload = ATLTestAttachmentDataFromStream(mediaAttachment.mediaInputStream);
    expect(payload).toNot.beNil();
    expect(payload).to.equal([NSJSONSerialization dataWithJSONObject:@{ @"lat": @(location.coordinate.latitude), @"lon":  @(location.coordinate.longitude) }  options:0 error:nil]);
}

- (void)testMediaWithImage
{
    UIImage *image = ATLTestAttachmentMakeImageWithSize(CGSizeMake(1024, 512));
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithImage:image metadata:@{ @"Orientation": @(UIImageOrientationUp) } thumbnailSize:512];
    
    // Verifying properties
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLImageMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Image");
    expect(mediaAttachment.thumbnailSize).to.equal(512);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"image/jpeg");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.equal(@"image/jpeg+preview");
    expect(mediaAttachment.thumbnailInputStream).toNot.beNil();
    expect(mediaAttachment.metadataMIMEType).to.equal(@"application/json+imageSize");
    expect(mediaAttachment.metadataInputStream).toNot.beNil();
    
    // Verifying stream content
    NSData *mediaPayload = ATLTestAttachmentDataFromStream(mediaAttachment.mediaInputStream);
    expect(mediaPayload).toNot.beNil();
    UIImage *processedImage = [UIImage imageWithData:mediaPayload];
    expect(processedImage.size).to.equal(CGSizeMake(1024, 512));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);

    // Verifying thumbnail content
    NSData *thumbnailPayload = ATLTestAttachmentDataFromStream(mediaAttachment.thumbnailInputStream);
    expect(thumbnailPayload).toNot.beNil();
    processedImage = [UIImage imageWithData:thumbnailPayload];
    expect(processedImage.size).to.equal(CGSizeMake(512, 256));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying image metadata JSON
    NSData *imageSizeMetadataJSON = ATLTestAttachmentDataFromStream(mediaAttachment.metadataInputStream);
    expect(imageSizeMetadataJSON).toNot.beNil();
    expect(imageSizeMetadataJSON).to.equal([NSJSONSerialization dataWithJSONObject:@{ @"width":@1024, @"height":@512, @"orientation":@(UIImageOrientationUp) } options:NSJSONWritingPrettyPrinted error:nil]);
}

- (void)testMediaAttachmentWithFileURLWithImage
{
    //Get Last Video
    // Generate a test image at a temporary path.
    NSURL *imageFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test-image.jpeg"]];
    [[NSFileManager defaultManager] removeItemAtURL:imageFileURL error:nil];
    UIImage *generatedTestImage = ATLTestAttachmentMakeImageWithSize(CGSizeMake(1920, 1080));
    NSData *imageData = UIImageJPEGRepresentation(generatedTestImage, 1.0);
    [imageData writeToURL:imageFileURL atomically:NO];
    expect([[NSFileManager defaultManager] fileExistsAtPath:imageFileURL.path]).to.beTruthy();
    
    //check properties of ATLMediaAttachment Object
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithFileURL:imageFileURL thumbnailSize:512];
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLAssetMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Image");
    expect(mediaAttachment.thumbnailSize).to.equal(512);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"image/jpeg");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.equal(@"image/jpeg+preview");
    expect(mediaAttachment.thumbnailInputStream).toNot.beNil();
    expect(mediaAttachment.metadataMIMEType).to.equal(@"application/json+imageSize");
    expect(mediaAttachment.metadataInputStream).toNot.beNil();
    
    // Verifying stream content
    NSInputStream *stream = mediaAttachment.mediaInputStream;
    [stream open];
    expect(stream.streamStatus).to.equal(NSStreamStatusOpen);
    expect(stream.streamError).to.beNil();
    
    NSData *mediaPayload = ATLTestAttachmentDataFromStream(mediaAttachment.mediaInputStream);
    expect(mediaPayload).toNot.beNil();
    UIImage *processedImage = [UIImage imageWithData:mediaPayload];
    expect(processedImage.size).to.equal(CGSizeMake(1920, 1080));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    [stream close];
    expect(stream.streamError).to.beNil();
    expect(stream.streamStatus).to.equal(NSStreamStatusClosed);
    NSString *path = [NSString stringWithFormat:@"%@result.jpeg", NSTemporaryDirectory()];
    [mediaPayload writeToFile:path atomically:NO];
    NSLog(@"check file: %@ length=%lu", path, mediaPayload.length);
    
    // Verifying thumbnail content
    NSData *thumbnailPayload = ATLTestAttachmentDataFromStream(mediaAttachment.thumbnailInputStream);
    expect(thumbnailPayload).toNot.beNil();
    processedImage = [UIImage imageWithData:thumbnailPayload];
    expect(processedImage.size).to.equal(CGSizeMake(512, 288));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying image metadata JSON
    NSData *imageSizeMetadataJSON = ATLTestAttachmentDataFromStream(mediaAttachment.metadataInputStream);
    expect(imageSizeMetadataJSON).toNot.beNil();
}

- (void)testMediaWithAsset
{
    [Expecta setAsynchronousTestTimeout:10];
    UIImage *image = ATLTestAttachmentMakeImageWithSize(CGSizeMake(1024, 512));

    // First, save the generated image to the album.
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block NSURL *assetURL;
    [library writeImageToSavedPhotosAlbum:image.CGImage metadata:@{ @"Orientation": @(UIImageOrientationUp) } completionBlock:^(NSURL *outAssetURL, NSError *error) {
        assetURL = outAssetURL;
    }];
    expect(assetURL).willNot.beNil();
    
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithAssetURL:assetURL thumbnailSize:512];
    
    // Verifying properties
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLAssetMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Image");
    expect(mediaAttachment.thumbnailSize).to.equal(512);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"image/jpeg");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.equal(@"image/jpeg+preview");
    expect(mediaAttachment.thumbnailInputStream).toNot.beNil();
    expect(mediaAttachment.metadataMIMEType).to.equal(@"application/json+imageSize");
    expect(mediaAttachment.metadataInputStream).toNot.beNil();
    
    // Verifying stream content
    NSData *mediaPayload = ATLTestAttachmentDataFromStream(mediaAttachment.mediaInputStream);
    expect(mediaPayload).toNot.beNil();
    UIImage *processedImage = [UIImage imageWithData:mediaPayload];
    expect(processedImage.size).to.equal(CGSizeMake(1024, 512));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying thumbnail content
    NSData *thumbnailPayload = ATLTestAttachmentDataFromStream(mediaAttachment.thumbnailInputStream);
    expect(thumbnailPayload).toNot.beNil();
    processedImage = [UIImage imageWithData:thumbnailPayload];
    expect(processedImage.size).to.equal(CGSizeMake(512, 256));
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying image metadata JSON
    NSData *imageSizeMetadataJSON = ATLTestAttachmentDataFromStream(mediaAttachment.metadataInputStream);
    expect(imageSizeMetadataJSON).toNot.beNil();
    expect(imageSizeMetadataJSON).to.equal([NSJSONSerialization dataWithJSONObject:@{ @"width":@1024, @"height":@512, @"orientation":@(UIImageOrientationUp) } options:NSJSONWritingPrettyPrinted error:nil]);
}

- (void)testMediaWithVideoAsset
{
    //Get Last Video
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    ALAsset *sourceAsset = ATLVideoAssetTestObtainLastVideoFromAssetLibrary(library);
    expect(sourceAsset).toNot.beNil();
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 1, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    int count;

    NSURL *lastVideoURL = sourceAsset.defaultRepresentation.url;

    //get original video length
    ALAssetRepresentation *rep = [sourceAsset defaultRepresentation];
    Byte *buffer1 = (Byte*)malloc(rep.size);
    NSError *error = nil;
    NSUInteger buffered = [rep getBytes:buffer1 fromOffset:0.0 length:rep.size error:&error];
    NSData *data1 = [NSData dataWithBytesNoCopy:buffer1 length:buffered freeWhenDone:YES];
    NSLog(@"Size of video %lu",(unsigned long)data1.length);
    expect(lastVideoURL).willNot.beNil();
    
    //check properties of ATLMediaAttachment Object
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithAssetURL:lastVideoURL thumbnailSize:512];
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLAssetMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Video");
    expect(mediaAttachment.thumbnailSize).to.equal(512);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"video/mp4");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.equal(@"video/mp4+preview");
    expect(mediaAttachment.thumbnailInputStream).toNot.beNil();
    expect(mediaAttachment.metadataMIMEType).to.equal(@"application/json+imageSize");
    expect(mediaAttachment.metadataInputStream).toNot.beNil();
    
    // Verifying stream content
    NSInputStream *stream = mediaAttachment.mediaInputStream;
    [stream open];
    expect(stream.streamStatus).to.equal(NSStreamStatusOpen);
    expect(stream.streamError).to.beNil();
    
    NSMutableData *data = [NSMutableData data];
    NSUInteger sizeOfBuffer = 512 * 1024;
    NSUInteger sizeOfRead = 512*1024;
    uint8_t *buffer = malloc(sizeOfBuffer);
    NSInteger bytesRead = 0;
    do {
        bytesRead = [stream read:buffer maxLength:sizeOfRead];
        expect(stream.streamError).to.beNil();
        [data appendBytes:buffer length:bytesRead];
    } while (bytesRead > 0);
    free(buffer);
    
    [stream close];
    expect(stream.streamError).to.beNil();
    expect(stream.streamStatus).to.equal(NSStreamStatusClosed);
    NSString *path = [NSString stringWithFormat:@"%@test.mp4", NSTemporaryDirectory()];
    [data writeToFile:path atomically:NO];
    NSLog(@"check file: %@ length=%lu", path, data.length);
    expect(data1.length).to.equal(data.length);

    //verify all files are cleaned
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    expect([directoryContent count]).to.equal(0);

    // Verifying thumbnail content
    NSData *thumbnailPayload = ATLTestAttachmentDataFromStream(mediaAttachment.thumbnailInputStream);
    expect(thumbnailPayload).toNot.beNil();
    UIImage *processedImage = [UIImage imageWithData:thumbnailPayload];
    expect(processedImage.size).toNot.beNil(); 
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying image metadata JSON
    NSData *imageSizeMetadataJSON = ATLTestAttachmentDataFromStream(mediaAttachment.metadataInputStream);
    expect(imageSizeMetadataJSON).toNot.beNil();
}

- (void)testMediaAttachmentWithFileURLWithVideo
{
    //Get Last Video
    // Generate video at a temporary path.
    NSURL *videoFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temporary-test-video.mov"]];
    ATLTestMakeVideo(videoFileURL, CGSizeMake(1280, 720), 30, 2);
    expect([[NSFileManager defaultManager] fileExistsAtPath:videoFileURL.path]).to.beTruthy();
    
    //check properties of ATLMediaAttachment Object
    ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithFileURL:videoFileURL thumbnailSize:512];
    expect(mediaAttachment).toNot.beNil();
    expect(NSStringFromClass(mediaAttachment.class)).to.equal(@"ATLAssetMediaAttachment");
    expect(mediaAttachment.textRepresentation).to.equal(@"Attachment: Video");
    expect(mediaAttachment.thumbnailSize).to.equal(512);
    expect(mediaAttachment.mediaMIMEType).to.equal(@"video/mp4");
    expect(mediaAttachment.mediaInputStream).toNot.beNil();
    expect(mediaAttachment.mediaInputStream.streamStatus).to.equal(NSStreamStatusNotOpen);
    expect(mediaAttachment.thumbnailMIMEType).to.equal(@"video/mp4+preview");
    expect(mediaAttachment.thumbnailInputStream).toNot.beNil();
    expect(mediaAttachment.metadataMIMEType).to.equal(@"application/json+imageSize");
    expect(mediaAttachment.metadataInputStream).toNot.beNil();
    
    // Verifying stream content
    NSInputStream *stream = mediaAttachment.mediaInputStream;
    [stream open];
    expect(stream.streamStatus).to.equal(NSStreamStatusOpen);
    expect(stream.streamError).to.beNil();
    
    NSMutableData *data = [NSMutableData data];
    NSUInteger sizeOfBuffer = 512 * 1024;
    NSUInteger sizeOfRead = 512*1024;
    uint8_t *buffer = malloc(sizeOfBuffer);
    NSInteger bytesRead = 0;
    do {
        bytesRead = [stream read:buffer maxLength:sizeOfRead];
        expect(stream.streamError).to.beNil();
        [data appendBytes:buffer length:bytesRead];
    } while (bytesRead > 0);
    free(buffer);
    
    [stream close];
    expect(stream.streamError).to.beNil();
    expect(stream.streamStatus).to.equal(NSStreamStatusClosed);
    NSString *path = [NSString stringWithFormat:@"%@result-video.mp4", NSTemporaryDirectory()];
    [data writeToFile:path atomically:NO];
    NSLog(@"check file: %@ length=%lu", path, data.length);
    
    // Verifying thumbnail content
    NSData *thumbnailPayload = ATLTestAttachmentDataFromStream(mediaAttachment.thumbnailInputStream);
    expect(thumbnailPayload).toNot.beNil();
    UIImage *processedImage = [UIImage imageWithData:thumbnailPayload];
    expect(processedImage.size).toNot.beNil();
    expect(processedImage.imageOrientation).to.equal(UIImageOrientationUp);
    
    // Verifying image metadata JSON
    NSData *imageSizeMetadataJSON = ATLTestAttachmentDataFromStream(mediaAttachment.metadataInputStream);
    expect(imageSizeMetadataJSON).toNot.beNil();
}

@end
