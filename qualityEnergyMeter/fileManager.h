//
//  fileManager.h
//  qualityEnergyMeter
//
//  Created by Jorge Macias on 5/9/14.
//  Copyright (c) 2014 Diincasa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface fileManager : NSObject
{
    NSFileManager *fileMgr;
    NSString *homeDir;
    NSString *filename;
    NSString *filepath;
}

@property(nonatomic,retain) NSFileManager *fileMgr;
@property(nonatomic,retain) NSString *homeDir;
@property(nonatomic,retain) NSString *filename;
@property(nonatomic,retain) NSString *filepath;

-(NSString *) GetDocumentDirectory;
-(void) WriteToStringFile:(NSMutableString *)textToWrite;
-(NSString *) readFromFile;
-(NSString *) setFilename;
@end
