// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "SymbolSearch.h"

#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_region.h>
#include <mach-o/dyld_images.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
typedef struct load_command load_command_t;
#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST "__DATA_CONST"
#endif

#ifndef SEG_AUTH_CONST
#define SEG_AUTH_CONST "__AUTH_CONST"
#endif


static inline int copySafely(const void *restrict const src, const int byteCount) {
    vm_size_t bytesCopied = 0;
    char buffer[byteCount];
    kern_return_t result = vm_read_overwrite(mach_task_self(),
                                             (vm_address_t)src,
                                             (vm_size_t)byteCount,
                                             (vm_address_t)buffer,
                                             &bytesCopied);
    if (result != KERN_SUCCESS) {
        return 0;
    }
    return (int)bytesCopied;
}

// KSCrash: KSMemory.c/ ksmem_copySafely(
static bool ksmem_readSafely(const void *restrict const src, const int byteCount) {
    return copySafely(src, byteCount);
}

static bool cstringPrefix(const char *str, const char *pre) {
    return strncmp(pre, str, strlen(pre)) == 0;
}

static void forEachLoadCommand(const struct mach_header *header, void (^callback)(const load_command_t *cmd, bool *stop)) {
    bool stop = false;
    const load_command_t *startCmds = NULL;
    if (header->magic == MH_MAGIC_64)
        startCmds = (load_command_t *)((char *)header + sizeof(struct mach_header_64));
    else if (header->magic == MH_MAGIC)
        startCmds = (load_command_t *)((char *)header + sizeof(struct mach_header));
    else if (header->magic == MH_CIGAM || header->magic == MH_CIGAM_64)
        return; // can't process big endian mach-o
    else {
        return; // not a mach-o file
    }
    const load_command_t *const cmdsEnd = (load_command_t *)((char *)startCmds + header->sizeofcmds);
    const load_command_t *cmd = startCmds;
    for (uint32_t i = 0; i < header->ncmds; ++i) {
        const load_command_t *nextCmd = (load_command_t *)((char *)cmd + cmd->cmdsize);
        if (cmd->cmdsize < 8) {
            return;
        }
        // FIXME: add check the cmdsize is pointer aligned (might reveal bin compat issues)
        if ((nextCmd > cmdsEnd) || (nextCmd < startCmds)) {
            return;
        }
        callback(cmd, &stop);
        if (stop)
            return;
        cmd = nextCmd;
    }
}

struct function_entry {
    struct FunctionSearch *searchs;
    struct function_entry *next;
    size_t link_list_len;
};

struct FunctionSearch makeFunctionSearch(const char *name, void *pointer) {
    struct FunctionSearch search = {0};
    name = name ?: "";
    search.name = strdup(name);
    search.pointer = pointer;
    return search;
}

static struct function_entry *_rebindings_head = NULL;

static int prepare_search(struct function_entry **rebindings_head,
                          struct FunctionSearch rebindings[],
                          size_t nel) {
    struct function_entry *new_entry = (struct function_entry *)malloc(sizeof(struct function_entry));
    if (!new_entry) {
        return -1;
    }
    new_entry->searchs = malloc(sizeof(struct FunctionSearch) * nel);
    memcpy(new_entry->searchs, rebindings, sizeof(struct FunctionSearch) * nel);
    if (!new_entry->searchs) {
        free(new_entry);
        return -1;
    }
    new_entry->link_list_len = nel;
    new_entry->next = *rebindings_head;
    *rebindings_head = new_entry;
    return 0;
}

static bool address_has_execute_protect(vm_address_t address) {
    vm_size_t region_size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;
    vm_address_t pageAddr = trunc_page(address);
    kern_return_t kr = vm_region_64(mach_task_self(), &pageAddr, &region_size, VM_REGION_BASIC_INFO_COUNT_64,
                      (vm_region_info_64_t)&info, &info_count, &object_name);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    if (info.protection & (VM_PROT_EXECUTE | VM_PROT_READ)) {
        return true;
    } else {
        return false;
    }
}

static void search_symbols_for_image(struct function_entry *rebindings,
                                     const struct mach_header *header,
                                     intptr_t slide) {
    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command *symtab_cmd = NULL;

    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        if (linkedit_segment && symtab_cmd) {
            break;
        }
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command *)cur_seg_cmd;
        }
    }

    if (!symtab_cmd || !linkedit_segment) {
        return;
    }

    // Find base symbol/string table addresses
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
    uint32_t cmdsize = symtab_cmd->nsyms;
    
    for (uint32_t i = 0; i < cmdsize; i++) {
        nlist_t *nlist = &symtab[i];

        if ((nlist->n_type & N_STAB) || (nlist->n_type & N_TYPE) != N_SECT) {
            continue;
        }
        
//        if (!ksmem_readSafely(nlist , sizeof(nlist_t))) {
//            fprintf(stderr, "unreadable for nlist_t  %p\n ", nlist);
//            continue;
//        }

        const char *symbol_name = strtab + nlist->n_un.n_strx;

//        if (!ksmem_readSafely(symbol_name, 2)) {
//            fprintf(stderr, "unreadable for strtab %p\n ", symbol_name);
//            continue;
//        }

        bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1];

        intptr_t functionAddress = (intptr_t)(nlist->n_value + slide);
        const char *name = rebindings->searchs[i].name;
        const char *alias = rebindings->searchs[i].alias;
		for (int i = 0; i < rebindings->link_list_len; i++) {
			if (symbol_name_longer_than_1 && cstringPrefix(symbol_name, "_") 
            && (strcmp(&symbol_name[1], name) == 0 || (alias && strcmp(&symbol_name[1], alias) == 0))) {
				if (address_has_execute_protect(functionAddress)) {
					*(rebindings->searchs[i].pointer) = (void *)(functionAddress);
				} else {
					fprintf(stderr, "SymbolSearch error for %s\n", rebindings->searchs[i].name);
					break;
				}
			}
		}
	}
    return;
}

int search_symbols(struct FunctionSearch rebindings[], size_t rebindings_nel) {
#if DEBUG
    struct timespec start_ts;
    clock_gettime(CLOCK_REALTIME, &start_ts);
    long milliseconds = start_ts.tv_sec * 1000 + start_ts.tv_nsec / 1000000;
#endif
        
    int retval = prepare_search(&_rebindings_head, rebindings, rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    
    for (int i = 0; i < _rebindings_head->link_list_len; i++) {
        if (strcmp("strlen", _rebindings_head->searchs[i].name) == 0) {
            _rebindings_head->searchs[i].alias = "_platform_strlen";
        }
    }

    kern_return_t kr;
    struct task_dyld_info dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;

    kr = task_info(mach_task_self(), TASK_DYLD_INFO, (task_info_t)&dyld_info, &count);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "task_info failed: %d\n", kr);
        return -1;
    }

    struct dyld_all_image_infos *all_image_infos = (struct dyld_all_image_infos *)dyld_info.all_image_info_addr;
    for (int i = 0; i < all_image_infos->infoArrayCount; i++) {
        struct dyld_image_info info = all_image_infos->infoArray[i];
        __block intptr_t slide = 0;
        const struct mach_header* header = info.imageLoadAddress;
        // dyld4: intptr_t MachOLoaded::getSlide()
        forEachLoadCommand(header, ^(const load_command_t *cmd, bool *stop) {
            if (cmd->cmd == LC_SEGMENT_64) {
                const segment_command_t* seg = (segment_command_t *)cmd;
                if (strcmp(seg->segname, "__TEXT") == 0 ) {
                    slide = (uintptr_t)((uintptr_t)header - (uintptr_t)seg->vmaddr);
                    *stop = true;
                }
            }
        });
        search_symbols_for_image(_rebindings_head, header, slide);
    }

    for (int i = 0; i < _rebindings_head->link_list_len; i++) {
        free((void *)_rebindings_head->searchs[i].name);
    }
    free(_rebindings_head->searchs);
    free(_rebindings_head);
    _rebindings_head = NULL;

#if DEBUG
    struct timespec end_ts;
    clock_gettime(CLOCK_REALTIME, &end_ts);
    long end_milliseconds = end_ts.tv_sec * 1000 + end_ts.tv_nsec / 1000000;
    printf("[OCRunner] search_symbols time cost %ld ms\n", end_milliseconds - milliseconds);
#endif
    return retval;
}
