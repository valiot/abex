/***************************************************************************
 *   Copyright (C) 2015 by OmanTek                                         *
 *   Author Kyle Hayes  kylehayes@omantek.com                              *
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


/**************************************************************************
 * CHANGE LOG                                                             *
 *                                                                        *
 * 2012-03-14  KRH - Created file.                                        *
 *                                                                        *
 * 2012-07-18  KRH - Updated code for changed library API.                *
 *                                                                        *
 * 2015-12-19  Jake - updated code to decode errors and other changes.    *
 *                                                                        *
 * 2015-12-20  KRH - removed getopt dependency and wrote direct           *
 *                   handling of options, fixed includes.                 *
 *                                                                        *
 * 2025-01-XX  Updated for libplctag v2.6.12 API                          *
 **************************************************************************/

#define POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include "compat_utils.h"
#include <libplctag/lib/libplctag.h>

#define PLC_LIB_UINT8   (0x108)
#define PLC_LIB_SINT8   (0x208)
#define PLC_LIB_UINT16  (0x110)
#define PLC_LIB_SINT16  (0x210)
#define PLC_LIB_UINT32  (0x120)
#define PLC_LIB_SINT32  (0x220)
#define PLC_LIB_UINT64  (0x140)
#define PLC_LIB_SINT64  (0x240)
#define PLC_LIB_REAL32  (0x320)
#define PLC_LIB_REAL64  (0x340)

#define DATA_TIMEOUT 5000
#define REQUIRED_VERSION 2, 2, 1

static int data_type = 0;
static char *write_str = NULL;
static char *path = NULL;

void parse_args(int argc, char **argv)
{
    int i = 1;

    while(i < argc) {
        if(!strcmp(argv[i],"-t")) {
            i++; /* get the arg next */
            if(i < argc) {
                if(!compat_strcasecmp("uint8",argv[i])) {
                    data_type = PLC_LIB_UINT8;
                } else if(!compat_strcasecmp("sint8",argv[i])) {
                    data_type = PLC_LIB_SINT8;
                } else if(!compat_strcasecmp("uint16",argv[i])) {
                    data_type = PLC_LIB_UINT16;
                } else if(!compat_strcasecmp("sint16",argv[i])) {
                    data_type = PLC_LIB_SINT16;
                } else if(!compat_strcasecmp("uint32",argv[i])) {
                    data_type = PLC_LIB_UINT32;
                } else if(!compat_strcasecmp("sint32",argv[i])) {
                    data_type = PLC_LIB_SINT32;
                } else if(!compat_strcasecmp("uint64",argv[i])) {
                    data_type = PLC_LIB_UINT64;
                } else if(!compat_strcasecmp("sint64",argv[i])) {
                    data_type = PLC_LIB_SINT64;
                } else if(!compat_strcasecmp("real32",argv[i])) {
                    data_type = PLC_LIB_REAL32;
                } else if(!compat_strcasecmp("real64",argv[i])) {
                    data_type = PLC_LIB_REAL64;
                } else {
                    fprintf(stderr, "ERROR: unknown data type: %s\n",argv[i]);
                    exit(1);
                }
            } else {
                fprintf(stderr, "ERROR: you must have a value after -t\n");
                exit(1);
            }
        } else if(!strcmp(argv[i],"-w")) {
            i++;
            if(i < argc) {
                write_str = compat_strdup(argv[i]);
            } else {
                fprintf(stderr, "ERROR: you must have a value to write after -w\n");
                exit(1);
            }
        } else if(!strcmp(argv[i],"-p")) {
            i++;
            if(i < argc) {
                path = compat_strdup(argv[i]);
            } else {
                fprintf(stderr, "ERROR: you must have a tag string after -p\n");
                exit(1);
            }
        }

        i++;
    }
}


int main(int argc, char **argv)
{
    int32_t tag = 0;
    int is_write = 0;
    uint64_t u_val;
    int64_t i_val;
    double f_val;
    int i;
    int rc;

    /* check library version */
    if(plc_tag_check_lib_version(REQUIRED_VERSION) != PLCTAG_STATUS_OK) {
        fprintf(stderr, "ERROR: Required library version %d.%d.%d not available!\n", REQUIRED_VERSION);
        exit(1);
    }

    parse_args(argc, argv);

    /* check arguments */
    if(!path || !data_type) {
        fprintf(stderr, "ERROR: Missing required arguments -p (path) or -t (type)\n");
        exit(1);
    }

    /* convert any write values */
    if(write_str && strlen(write_str)) {
        is_write = 1;

        switch(data_type) {
        case PLC_LIB_UINT8:
        case PLC_LIB_UINT16:
        case PLC_LIB_UINT32:
        case PLC_LIB_UINT64:
            if(compat_sscanf(write_str,"%" SCNu64,&u_val) != 1) {
                fprintf(stderr, "ERROR: bad format for unsigned integer for write value.\n");
                exit(1);
            }
            break;

        case PLC_LIB_SINT8:
        case PLC_LIB_SINT16:
        case PLC_LIB_SINT32:
        case PLC_LIB_SINT64:
            if(compat_sscanf(write_str,"%" SCNd64,&i_val) != 1) {
                fprintf(stderr, "ERROR: bad format for signed integer for write value.\n");
                exit(1);
            }
            break;

        case PLC_LIB_REAL32:
        case PLC_LIB_REAL64:
            if(compat_sscanf(write_str,"%lf",&f_val) != 1) {
                fprintf(stderr, "ERROR: bad format for floating point for write value.\n");
                exit(1);
            }
            break;

        default:
            fprintf(stderr, "ERROR: bad data type!\n");
            exit(1);
            break;
        }
    } else {
        is_write = 0;
    }

    /* create the tag */
    tag = plc_tag_create(path, DATA_TIMEOUT);
    if(tag < 0) {
        fprintf(stderr, "ERROR %s: error creating tag!\n", plc_tag_decode_error(tag));
        if(path) free(path);
        if(write_str) free(write_str);
        exit(1);
    }

    if((rc = plc_tag_status(tag)) != PLCTAG_STATUS_OK) {
        fprintf(stderr, "ERROR: tag creation error, tag status: %s\n",plc_tag_decode_error(rc));
        plc_tag_destroy(tag);
        if(path) free(path);
        if(write_str) free(write_str);
        exit(1);
    }

    do {
        if(!is_write) {
            int index = 0;

            rc = plc_tag_read(tag, DATA_TIMEOUT);
            if(rc != PLCTAG_STATUS_OK) {
                fprintf(stderr, "ERROR: tag read error, tag status: %s\n",plc_tag_decode_error(rc));
                exit(1);
            }

            /* display the data */
            for(i=0; index < plc_tag_get_size(tag); i++) {
                switch(data_type) {
                case PLC_LIB_UINT8:
                    printf("%u ", plc_tag_get_uint8(tag,index));
                    index += 1;
                    break;

                case PLC_LIB_UINT16:
                    printf("%u ", plc_tag_get_uint16(tag,index));
                    index += 2;
                    break;

                case PLC_LIB_UINT32:
                    printf("%u ", plc_tag_get_uint32(tag,index));
                    index += 4;
                    break;

                case PLC_LIB_UINT64:
                    printf("%" PRIu64 " ", plc_tag_get_uint64(tag,index));
                    index += 8;
                    break;

                case PLC_LIB_SINT8:
                    printf("%d ", plc_tag_get_int8(tag,index));
                    index += 1;
                    break;

                case PLC_LIB_SINT16:
                    printf("%d ", plc_tag_get_int16(tag,index));
                    index += 2;
                    break;

                case PLC_LIB_SINT32:
                    printf("%d ", plc_tag_get_int32(tag,index));
                    index += 4;
                    break;

                case PLC_LIB_SINT64:
                    printf("%" PRId64 " ", plc_tag_get_int64(tag,index));
                    index += 8;
                    break;

                case PLC_LIB_REAL32:
                    printf("%f ", plc_tag_get_float32(tag,index));
                    index += 4;
                    break;

                case PLC_LIB_REAL64:
                    printf("%lf ", plc_tag_get_float64(tag,index));
                    index += 8;
                    break;
                }
            }
        } else {
            switch(data_type) {
            case PLC_LIB_UINT8:
                rc = plc_tag_set_uint8(tag,0,(uint8_t)u_val);
                break;

            case PLC_LIB_UINT16:
                rc = plc_tag_set_uint16(tag,0, (uint16_t)u_val);
                break;

            case PLC_LIB_UINT32:
                rc = plc_tag_set_uint32(tag,0,(uint32_t)u_val);
                break;

            case PLC_LIB_UINT64:
                rc = plc_tag_set_uint64(tag,0,(uint64_t)u_val);
                break;

            case PLC_LIB_SINT8:
                rc = plc_tag_set_int8(tag,0,(int8_t)i_val);
                break;

            case PLC_LIB_SINT16:
                rc = plc_tag_set_int16(tag,0,(int16_t)i_val);
                break;

            case PLC_LIB_SINT32:
                rc = plc_tag_set_int32(tag,0,(int32_t)i_val);
                break;

            case PLC_LIB_SINT64:
                rc = plc_tag_set_int64(tag,0,(int64_t)i_val);
                break;

            case PLC_LIB_REAL32:
                rc = plc_tag_set_float32(tag,0,(float)f_val);
                break;

            case PLC_LIB_REAL64:
                rc = plc_tag_set_float64(tag,0,f_val);
                break;
            }

            if(rc != PLCTAG_STATUS_OK) {
                fprintf(stderr, "ERROR: error setting data: %s!\n",plc_tag_decode_error(rc));
                break;
            }

            /* write the data */
            rc = plc_tag_write(tag, DATA_TIMEOUT);
            if(rc != PLCTAG_STATUS_OK) {
                fprintf(stderr, "ERROR: error writing data: %s!\n",plc_tag_decode_error(rc));
            } else {
                printf("%s ",write_str);
            }
        }
    } while(0);

    if(write_str) {
        free(write_str);
    }

    if(path) {
        free(path);
    }

    if(tag) {
        plc_tag_destroy(tag);
    }

    return 0;
}
