#ifndef GLOBUS_DONT_DOCUMENT_INTERNAL
/**
 * @file globus_gss_assist_constants.h
 * Globus GSI GSS Assist Library
 * @author Sam Lang, Sam Meder
 *
 * $RCSfile$
 * $Revision$
 * $Date$
 */
#endif

#ifndef GLOBUS_GSI_GSS_ASSIST_CONSTANTS_H
#define GLOBUS_GSI_GSS_ASSIST_CONSTANTS_H

/**
 * @defgroup globus_gsi_gss_assist_constants 
 * GSI GSS Assist Constants
 */
/* GSI GSS Assist Error codes
 * @ingroup globus_gsi_gss_assist_constants
 */
typedef enum
{
    GLOBUS_GSI_GSS_ASSIST_ERROR_SUCCESS = 0,
    GLOBUS_GSI_GSS_ASSIST_ERROR_WITH_ARGUMENTS = 1,
    GLOBUS_GSI_GSS_ASSIST_ERROR_USER_ID_DOESNT_MATCH = 2,
    GLOBUS_GSI_GSS_ASSIST_ERROR_IN_GRIDMAP_NO_USER_ENTRY = 3,
    GLOBUS_GSI_GSS_ASSIST_ERROR_WITH_GRIDMAP = 4,
    GLOBUS_GSI_GSS_ASSIST_ERROR_INVALID_GRIDMAP_FORMAT = 5,
    GLOBUS_GSI_GSS_ASSIST_ERROR_ERRNO = 6,
    GLOBUS_GSI_GSS_ASSIST_ERROR_WITH_INIT = 7,
    GLOBUS_GSI_GSS_ASSIST_ERROR_WITH_WRAP = 8,
    GLOBUS_GSI_GSS_ASSIST_ERROR_WITH_TOKEN = 9,
    GLOBUS_GSI_GSS_ASSIST_ERROR_EXPORTING_CONTEXT = 10,
    GLOBUS_GSI_GSS_ASSIST_ERROR_IMPORTING_CONTEXT = 11,
    GLOBUS_GSI_GSS_ASSIST_ERROR_LAST = 12
} globus_gsi_gss_assist_error_t;

#endif
