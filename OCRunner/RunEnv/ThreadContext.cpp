//
//  ThreadContext.cpp
//  OCRunner
//
//  Created by APPLE on 2021/7/14.
//

#include "ThreadContext.hpp"
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include <math.h>

machine_mem ThreadContext::push_localvar(void *var, size_t size){
    machine_mem dst = mem + sp + cursor;
    assert(dst < mem_end);
    assert(var != NULL);
    if (*(void **)var != NULL) {
        memcpy(dst, var , size);
    }else{
        memset(dst, 0, size);
    }
    cursor += size < 8 ? 8 : size;
    return dst;
}
void *ThreadContext::seek_localvar( mem_cursor offset){
    return mem + sp + offset;
}
void ThreadContext::enter_call(void){
    lr = sp + cursor;
    assert(mem + lr < mem_end);
    memcpy(mem + lr, &sp, sizeof(mem_cursor));
    sp = lr + sizeof(mem_cursor);
    cursor = 0;
}
void ThreadContext::exit_call(void){
    mem_cursor before = lr;
    memcpy(&sp, mem + lr, sizeof(mem_cursor));
    if (sp == 0) {
        lr = 0;
        cursor = 0;
    }else{
        lr = sp - sizeof(mem_cursor);
    }
    cursor = before - sp;
}
bool ThreadContext::is_calling(void){
    if (lr == sp) return false;
    return true;
}

void ThreadContext::temp_mem_pop(void){
    op_temp_mem_top--;
}
or_value_box *ThreadContext::tempmem_write_top( or_value_box *var){
    op_temp_mem[op_temp_mem_top] = *var;
    return op_temp_mem + op_temp_mem_top;
}
or_value_box *ThreadContext::tempmem_push( or_value_box *var){
    op_temp_mem[op_temp_mem_top++] = *var;
    assert(op_mem + op_temp_mem_top < op_mem_end);
    return op_temp_mem + op_temp_mem_top - 1;
}
or_value_box *ThreadContext::tempmem_top_var(void){
    return op_temp_mem + op_temp_mem_top;
}
or_value_box *ThreadContext::tempmem_seek( mem_cursor beforeTop){
    return op_temp_mem + op_temp_mem_top - beforeTop;
}

or_value * ThreadContext::op_stack_pop(void){
    temp_mem_pop();
    op_mem_top--;
    return op_mem + op_mem_top;
}
void ThreadContext::op_stack_write_top(or_value var){
    var.pointer = (void **)tempmem_write_top(&var.box);
    op_mem[op_mem_top] = var;
}
void ThreadContext::op_stack_push(or_value var){
    var.pointer = (void **)tempmem_push(&var.box);
    op_mem[op_mem_top++] = var;
    assert(op_mem + op_mem_top < op_mem_end);
}
or_value * ThreadContext::op_stack_top_var(void){
    return op_mem + op_mem_top;
}
or_value * ThreadContext::op_stack_seek( mem_cursor beforeTop){
    return op_mem + op_mem_top - 1 - beforeTop;
}
