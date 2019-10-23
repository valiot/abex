/***************************************************************************
 *   Copyright (C) 2017 by Kyle Hayes                                      *
 *   Author Kyle Hayes  kyle.hayes@gmail.com                               *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Library General Public License as       *
 *   published by the Free Software Foundation; either version 2 of the    *
 *   License, or (at your option) any later version.                       *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU Library General Public     *
 *   License along with this program; if not, write to the                 *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/



#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "libplctag/src/lib/libplctag.h"
#include "libplctag/src/examples/utils.h"


#define TAG_STRING_SIZE (200)
#define TIMEOUT_MS (5000)

struct program_entry_s {
    struct program_entry_s *next;
    char *program_name;
};


int32_t setup_tag(char *plc_ip, char *path, char *program)
{
    int32_t tag = PLCTAG_ERR_CREATE;
    char tag_string[TAG_STRING_SIZE] = {0,};

    if(!program || strlen(program) == 0) {
        snprintf(tag_string, TAG_STRING_SIZE-1,"protocol=ab-eip&gateway=%s&path=%s&cpu=lgx&name=@tags", plc_ip, path);
    } else {
        snprintf(tag_string, TAG_STRING_SIZE-1,"protocol=ab-eip&gateway=%s&path=%s&cpu=lgx&name=%s.@tags", plc_ip, path, program);
    }

    tag = plc_tag_create(tag_string, TIMEOUT_MS);
    if(tag < 0) {
        printf("Unable to open tag!  Return code %s\n", plc_tag_decode_error(tag));
        exit(1);
    }

    return tag;
}


void get_list(int32_t tag, struct program_entry_s **head)
{
    int rc = PLCTAG_STATUS_OK;
    int offset = 0;
    int index = 0;

    rc = plc_tag_read(tag, TIMEOUT_MS);
    if(rc != PLCTAG_STATUS_OK) {
        printf("Unable to read tag!  Return code %s\n",plc_tag_decode_error(tag));
        exit(1);
    }

    do {
        uint32_t tag_instance_id = 0;
        uint16_t tag_type = 0;
        uint16_t element_length = 0;
        uint16_t tag_name_len = 0;
        uint32_t array_dims[3] = {0,};
        char tag_name[TAG_STRING_SIZE * 2] = {0,};

        //offset = index * 104; /* MAGIC - size of a symbol entry. */

        /* each entry looks like this:
        uint32_t instance_id    monotonically increasing but not contiguous
        uint16_t symbol_type    type of the symbol.
        uint16_t element_length length of one array element in bytes.
        uint32_t array_dims[3]  array dimensions.
        uint16_t string_len     string length count.
        uint8_t string_data[]   string bytes (string_len of them)
        */

        tag_instance_id = plc_tag_get_uint32(tag, offset);
        offset += 4;

        tag_type = plc_tag_get_uint16(tag, offset);
        offset += 2;

        element_length = plc_tag_get_uint16(tag, offset);
        offset += 2;

        array_dims[0] = plc_tag_get_uint32(tag, offset);
        offset += 4;
        array_dims[1] = plc_tag_get_uint32(tag, offset);
        offset += 4;
        array_dims[2] = plc_tag_get_uint32(tag, offset);
        offset += 4;

        tag_name_len = plc_tag_get_uint16(tag, offset);
        offset += 2;

        for(int i=0;i < (int)tag_name_len && i<((TAG_STRING_SIZE*2)-1);i++) {
            tag_name[i] = plc_tag_get_int8(tag,offset);
            offset++;
            tag_name[i+1] = 0;
        }

        index++;

        printf("tag_name=%s; tag_instance_id=%x; tag_type=%x; element_length=%d; array_dimensions=(%d, %d, %d)\n", tag_name, tag_instance_id, tag_type, (int)element_length, (int)array_dims[0], (int)array_dims[1], (int)array_dims[2]);

        if(head && strncmp(tag_name, "Program:", strlen("Program:")) == 0) {
            struct program_entry_s *entry = malloc(sizeof(*entry));

            if(!entry) {
                fprintf(stderr,"Unable to allocate memory for program entry!\n");
                exit(1);
            }

            entry->next = *head;
            entry->program_name = strdup(tag_name);

            *head = entry;
        }
    } while(rc == PLCTAG_STATUS_OK && offset < plc_tag_get_size(tag));

    plc_tag_destroy(tag);
}




int main(int argc, char **argv)
{
    int32_t tag;
    struct program_entry_s *programs = NULL;

    if(argc < 3) {
        exit(1);
    }

    if(!argv[1] || strlen(argv[1]) == 0) {
        printf("Hostname or IP address must not be zero length!\n");
        exit(1);
    }

    if(!argv[2] || strlen(argv[2]) == 0) {
        printf("PLC path must not be zero length!\n");
        exit(1);
    }

    /* get the controller tags first. */
    tag = setup_tag(argv[1], argv[2], NULL);

    get_list(tag, &programs);

    /* get the tags for program. */
    printf("Program tags\n");
    while(programs) {
        struct program_entry_s *program = programs;
        printf("\r\n%s!", program->program_name);
        tag = setup_tag(argv[1], argv[2], program->program_name);
        get_list(tag, NULL);

        /* go to the next one */
        programs = programs->next;

        /* now clean up */
        free(program->program_name);
        free(program);
    }

    return 0;
}
