#!/usr/bin/python

# Copyright 2012-2013 University of Chicago
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Configure a MyProxy server for use with Globus Online

globus-connect-multiuser-id-setup [-h|--help]
globus-connect-multiuser-id-setup {-c FILENAME|--config-file=FILENAME}
                                  {-v|--verbose}
                                  {-r PATH|--root=PATH}

The globus-connect-multiuser-id-setup command generates MyProxy service
configuration based on the globus-connect-multiuser configuration file, and
starts the MyProxy server. Depending on features enabled in the configuration
file, this process will include fetching a service credential from the Globus
Connect CA, writing MyProxy configuration files in the /etc/myproxy.d/
directory, restarting the MyProxy server, and enabling the MyProxy server to
start at boot.

If the -r PATH or --root=PATH command-line option is used,
globus-connect-multiuser-id-setup will write its MyProxy configuration and
certificates in a subdirectory rooted at PATH instead of /. This means, for
example, that globus-connect-multiuser-id-setup writes MyProxy configuration
files in PATH/etc/gridftp.d.

The following options are available:

-h, --help
                                Display help information
-c FILENAME, --config-file=FILENAME
                                Use configuration file FILENAME instead of
                                /etc/globus-connect-multiuser.conf
-v, --verbose	                Print more information about tasks
-r PATH, --root=PATH	        Add PATH as the directory prefix for the
                                configuration files that
                                globus-connect-multiuser-id-setup writes
"""

short_usage = """globus-connect-multiuser-id-setup [-h|--help]
globus-connect-multiuser-id-setup {-c FILENAME|--config-file=FILENAME}
                                  {-v|--verbose}
                                  {-r PATH|--root=PATH}
"""

import getopt
import getpass
import socket
import ssl
import sys
import time
import traceback

from globusonline.transfer.api_client.goauth import get_access_token, GOCredentialsError
from globusonline.transfer.api_client import TransferAPIClient
from globus.connect.multiuser import get_api
from globus.connect.multiuser.id import ID
from globus.connect.multiuser.configfile import ConfigFile

def usage(short=False, outstream=sys.stdout):
    if short:
        print >>outstream, short_usage
    else:
        print >>outstream, __doc__

if __name__ == "__main__":
    conf_filename = None
    api = None
    force = False
    debug = False
    root = "/"
    try:
        opts, arg = getopt.getopt(sys.argv[1:], "hc:vr:",
                ["help", "config-file=", "verbose", "root="])
    except getopt.GetoptError, e:
        print >>sys.stderr, "Invalid option " + e.opt
        usage(short=True, outstream=sys.stderr)
        sys.exit(1)
    
    if len(arg) > 0:
        print >>sys.stderr, "Unexpected argument(s) " + " ".join(arg)
        sys.exit(1)

    for (o, val) in opts:
        if o in ['-h', '--help']:
            usage()
            sys.exit(0)
        elif o in ['-c', '--config-file']:
            conf_filename = val
        elif o in ['-v',  '--verbose']:
            debug = True
        elif o in ['-r', '--root']:
            root = val
        else:
            print >>sys.stderr, "Unknown option %s" %(o)
            sys.exit(1)

    try:
        conf = ConfigFile(config_file=conf_filename, root=root)
        api = get_api(conf)
        id = ID(config_obj=conf, api=api, debug=debug)
        id.setup()
        sys.exit(id.errorcount)
    except KeyboardInterrupt, e:
        print "Aborting.."
        sys.exit(1);
    except Exception, e:
        if debug:
            traceback.print_exc(file=sys.stderr)
        else:
            print str(e)
        sys.exit(1)


# vim: filetype=python:
