//
//  ORParserForTest.m
//  OCRunnerDemoTests
//
//  Created by APPLE on 2021/6/16.
//  Copyright © 2021 SilverFruity. All rights reserved.
//

#import "ORParserForTest.h"

@implementation ORParserForTest
- (AST *)parseCodeSource:(CodeSource *)source{
    [super parseCodeSource:source];
    do {
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *filePath = [cachePath stringByAppendingPathComponent:@"BinaryPatch.png"];
        ORPatchFile *file = [[ORPatchFile alloc] initWithNodes:GlobalAst.nodes];
        filePath = [file dumpAsBinaryPatch:filePath];
        ORPatchFile *newFile = [ORPatchFile loadBinaryPatch:filePath];
        if (newFile) {
            GlobalAst = [AST new];
            [GlobalAst merge:newFile.nodes];
        }
    } while (0);
    return GlobalAst;
}
@end
