//
//  ThreadContext.hpp
//  OCRunner
//
//  Created by APPLE on 2021/7/14.
//

#ifndef ThreadContext_hpp
#define ThreadContext_hpp

#include <stdio.h>

typedef enum {
    ORControlFlowFlagNormal = 0x00,
    ORControlFlowFlagBreak = 0x01,
    ORControlFlowFlagContinue = 0x02,
    ORControlFlowFlagReturn = 0x10 << 1,
}ORControlFlowFlag;

typedef union{
    bool boolValue;
    char charValue;
    short shortValue;
    int intValue;
    long longValue;
    long long longlongValue;
    unsigned char uCharValue;
    unsigned short uShortValue;
    unsigned int uIntValue;
    unsigned long uLongValue;
    unsigned long long uLongLongValue;
    float floatValue;
    double doubleValue;
    void *pointerValue;
}or_value_box;

typedef struct{
    or_value_box box;
    void **pointer;
    const char *typeencode;
}or_value;


typedef long long mem_cursor;
typedef char * machine_mem;
typedef or_value *op_stack_mem;
typedef or_value_box *op_temp_value_mem;

class ThreadContext {
protected:
    mem_cursor lr;
    mem_cursor sp;
    mem_cursor cursor;
    
    machine_mem mem;
    machine_mem mem_end;
    
    op_stack_mem op_mem;
    op_stack_mem op_mem_end;
    mem_cursor op_mem_top;
    
    op_temp_value_mem op_temp_mem;
    op_temp_value_mem op_temp_mem_end;
    mem_cursor op_temp_mem_top;

    ORControlFlowFlag flow_flag;
    
public:
    machine_mem push_localvar( void *var, size_t size);
    void *seek_localvar( mem_cursor offset);
    void enter_call(void);
    void exit_call(void);
    bool is_calling(void);

    void temp_mem_pop(void);
    or_value_box *tempmem_write_top( or_value_box *var);
    or_value_box *tempmem_push( or_value_box *var);
    or_value_box *tempmem_top_var(void);
    or_value_box *tempmem_seek( mem_cursor beforeTop);

    or_value * op_stack_pop(void);
    void op_stack_write_top(or_value var);
    void op_stack_push(or_value var);
    or_value * op_stack_top_var(void);
    or_value * op_stack_seek( mem_cursor beforeTop);
};

#endif /* ThreadContext_hpp */
