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

struct rebindings_entry {
    struct FunctionSearch search;
    struct rebindings_entry *next;
    size_t link_list_len;
};

struct FunctionSearch makeFunctionSearch(const char *name, void *pointer) {
    struct FunctionSearch search;
    name = name ?: "";
    search.name = strdup(name);
    search.pointer = pointer;
    return search;
}

static struct rebindings_entry *_rebindings_head = NULL;
static bool _is_first_search = true;

static int prepend_search(struct rebindings_entry **rebindings_head,
                          struct FunctionSearch rebindings[],
                          size_t nel) {
    for (int i = 0; i < nel; i++) {
        struct FunctionSearch search = rebindings[i];
        struct rebindings_entry *new_entry = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
        memcpy(&(new_entry->search), &search, sizeof(struct FunctionSearch));
        new_entry->link_list_len = nel;
        if (new_entry->search.name == NULL) continue;
        new_entry->next = *rebindings_head;
        *rebindings_head = new_entry;
    }
    return 0;
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

static void forEachSection(const struct mach_header *header, void (^callback)(const section_t *sectInfo, bool *stop)) {
    __block uint32_t segIndex = 0;
    forEachLoadCommand(header, ^(const load_command_t *cmd, bool *stop) {
        if (cmd->cmd == LC_SEGMENT_64) {
            const segment_command_t *segCmd = (segment_command_t *)cmd;
            const section_t *const sectionsStart = (section_t *)((char *)segCmd + sizeof(segment_command_t));
            const section_t *const sectionsEnd = &sectionsStart[segCmd->nsects];
            for (const section_t *sect = sectionsStart; !(*stop) && (sect < sectionsEnd); ++sect) {
                callback(sect, stop);
            }
            ++segIndex;
        }
    });
}

//edit from dyld: bool MachOAnalyzer::inCodeSection
static bool inCodeSection(const struct mach_header *header, intptr_t slide, intptr_t address) {
    __block bool result = false;
    forEachSection(header, ^(const section_t *sectInfo, bool *stop) {
        if ((sectInfo->addr + slide <= address) && (address < (sectInfo->addr + sectInfo->size + slide))) {
            result = ((sectInfo->flags & S_ATTR_PURE_INSTRUCTIONS) || (sectInfo->flags & S_ATTR_SOME_INSTRUCTIONS));
            *stop = true;
        }
    });
    return result;
}

static void search_symbols_for_image(struct rebindings_entry *rebindings,
                                     const struct mach_header *header,
                                     intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }

    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command *symtab_cmd = NULL;

    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
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

    void *free_list[rebindings->link_list_len];
    size_t free_list_len = 0;
    for (uint32_t i = 0; i < cmdsize; i++) {
        nlist_t *nlist = &symtab[i];

        if ((nlist->n_type & N_STAB) || (nlist->n_type & N_TYPE) != N_SECT) {
            continue;
        }

        const char *symbol_name = strtab + nlist->n_un.n_strx;
        bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1];
        // <redirect>
        // $ ___Z C++
        // +/- objc
        // __swift swift
        if (!symbol_name_longer_than_1
            || symbol_name[0] == '<'
            || symbol_name[0] == '-'
            || symbol_name[0] == '+'
            || symbol_name[1] == '$'
            || cstringPrefix(symbol_name, "__Z")
            || cstringPrefix(symbol_name, "___")
            || cstringPrefix(symbol_name, "__swift")) {
            continue;
        }

        intptr_t functionAddress = (intptr_t)(nlist->n_value + slide);
        if (!inCodeSection(header, slide, functionAddress)) {
            continue;
        }

        struct rebindings_entry *cur = rebindings;
        struct rebindings_entry *prev = NULL;
        while (cur) {
            if (symbol_name_longer_than_1 && strcmp(&symbol_name[1], cur->search.name) == 0) {
                if (cur->search.pointer != NULL) {
                    *(cur->search.pointer) = (void *)(functionAddress);
                    if (prev) {
                        prev->next = cur->next;
                        free_list[free_list_len++] = cur;
                    }
                }
            }
            prev = cur;
            cur = cur->next;
        }
    }

    for (int i = 0; i < free_list_len; i++) {
        struct rebindings_entry *cur = free_list[i];
        free((void *)cur->search.name);
        free(cur);
    }

    return;
}

static void _rebind_symbols_for_image(const struct mach_header *header,
                                      intptr_t slide) {
    search_symbols_for_image(_rebindings_head, header, slide);
}

int search_symbols(struct FunctionSearch rebindings[], size_t rebindings_nel) {
    int retval = prepend_search(&_rebindings_head, rebindings, rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    // If this was the first call, register callback for image additions (which is also invoked for
    // existing images, otherwise, just run on existing images
    if (!_is_first_search) {
        _dyld_register_func_for_add_image(_rebind_symbols_for_image);
        _is_first_search = false;
    } else {
        uint32_t c = _dyld_image_count();
        for (uint32_t i = 0; i < c; i++) {
            _rebind_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
        }
    }
    return retval;
}
