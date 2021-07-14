//
//  MFBlock.h
//  MangoFix
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ORPatchFile/RunnerClasses.h>
#import "MFScopeChain.h"
enum {
	BLOCK_DEALLOCATING =      (0x0001),
	BLOCK_REFCOUNT_MASK =     (0xfffe),
	BLOCK_CREATED_FROM_MFGO =	(1 << 23),
	BLOCK_NEEDS_FREE =        (1 << 24),
	BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
	BLOCK_HAS_CTOR =          (1 << 26),
	BLOCK_IS_GC =             (1 << 27),
	BLOCK_IS_GLOBAL =         (1 << 28),
	BLOCK_USE_STRET =         (1 << 29),
	BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

struct MFSimulateBlock {
	void *isa;
	int flags;
	int reserved;
	void *invoke;
	struct MFGOSimulateBlockDescriptor *descriptor;
	void *wrapper;
};

struct MFGOSimulateBlockDescriptor {
	//Block_descriptor_1
	struct {
		unsigned long int reserved;
		unsigned long int size;
	};
	
	//Block_descriptor_2
	struct {
		// requires BLOCK_HAS_COPY_DISPOSE
		void (*copy)(void *dst, const void *src);
		void (*dispose)(const void *);
	};
	
	//Block_descriptor_3
	struct {
		// requires BLOCK_HAS_SIGNATURE
		const char *signature;
	};
};

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

const char *NSBlockGetSignature(void * block);
BOOL NSBlockHasSignature(void * block);
void NSBlockSetSignature(void * block, const char *typeencode);
void *simulateNSBlock(const char* typeEncoding, void *imp, void *userdata);
#ifdef __cplusplus
}
#endif //__cplusplus


@interface MFBlock : NSObject

@property (strong, nonatomic) MFScopeChain *outScope;
@property (strong, nonatomic) ORFunctionNode *func;
@property (strong, nonatomic) NSMutableArray <ORDeclaratorNode *>*paramTypes;
@property (strong, nonatomic) ORDeclaratorNode *retType;
- (id)ocBlock;
@end
