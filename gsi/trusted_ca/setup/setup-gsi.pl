

# 
# Copyright 1999-2006 University of Chicago
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

#
# Set up GSI configuration in /etc/grid-security
#
# This script is intended to be run as root.
#

use Getopt::Long;
use English;
use File::Path;

my $globusdir = $ENV{GLOBUS_LOCATION};

if (!defined($globusdir)) 
{
  die "GLOBUS_LOCATION needs to be set before running this script";
}

my $gpath = $ENV{GPT_LOCATION};

if (!defined($gpath))
{
  $gpath = $globusdir;

}

@INC = (@INC, "$gpath/lib/perl");

require Grid::GPT::Setup;

if( ! &GetOptions("nonroot|d:s","help!","default!") ) 
{
   pod2usage(1);
}

if(defined($opt_help))
{
   pod2usage(0);
}

my $setupdir = "$globusdir/setup/globus/";

my $target_dir = "";
my $trusted_certs_dir = "";

my $ca_install_hash = "42864e48";

my $installed_cert_hash = undef;

if(defined($opt_nonroot))
{
    if($opt_nonroot eq "") 
    {
	$target_dir = $globusdir . "/etc/";
    } 
    else 
    {
	$target_dir = "$opt_nonroot";
    }

    $trusted_certs_dir = $globusdir . "/share/certificates/";
}
else
{
   $target_dir = "/etc/grid-security";
   $trusted_certs_dir = $target_dir . "/certificates/";
}
    
$ENV{GRID_SECURITY_DIR} = "$target_dir";
$ENV{TRUSTED_CA_DIR}    = "$trusted_certs_dir";


my $myname = "setup-gsi";

print "$myname: Configuring GSI security\n";

#
# Create /etc/grid-security if not already there.
# If it is there, make sure we have write permissions
#
if ( -d $target_dir ) 
{
  if ( ! -w $target_dir ) 
  {
    die "Don't have write permissions on $target_dir. Aborting.";
  }
} 
else 
{

  print "Making $target_dir...\n";

  $result = mkpath("$target_dir",1,0755);

  if ($result == 0) 
  {
    die "Failed to create $target_dir. Aborting.";
  }

}

#
# Create trusted certificate directory if not present
#
if ( -d $trusted_certs_dir ) 
{
    if ( ! -w $trusted_certs_dir ) 
    {
        die "Don't have write permissions on $trusted_certs_dir. Aborting.";
    }
} 
else 
{
    print "Making trusted certs directory: $trusted_certs_dir\n";
    
    $result = mkpath("$trusted_certs_dir",1,0755);
    
    if ($result == 0) 
    {
        die "Failed to create $trusted_certs_dir. Aborting.";
    }
}

#
# Create /etc/grid-security/grid-security.conf if not present
#
print "Installing $trusted_certs_dir/grid-security.conf.$ca_install_hash...\n";

$result = system("cp $setupdir/grid-security.conf.$ca_install_hash $trusted_certs_dir/grid-security.conf.$ca_install_hash");

if ($result != 0) 
{
  die "Failed to install grid-security.conf.$ca_install_hash Aborting.";
}

$result = system("chmod 0644 $trusted_certs_dir/grid-security.conf.$ca_install_hash");

if ($result != 0) 
{
  die "Failed to set permissions on grid-security.conf.$ca_install_hash Aborting.";
}

#
# Run grid-security-config to generate globus-host-ssl.conf
# and globus-user-ssl.conf in $trusted_certs_dir
# Note that this script is interactive.
#
print "Running grid-security-config...\n";

$result = system("$setupdir/grid-security-config");

if ($result != 0) 
{
  die "Error running grid-security-config. Aborting.";
}


#
# Install Globus CA certificate if not present
#
print "Installing Globus CA certificate into trusted CA certificate directory...\n";

$result = system("cp $setupdir/${ca_install_hash}.0 $trusted_certs_dir");

if ($result != 0) 
{
  die "Failed to install $trusted_certs_dir/${ca_install_hash}.0. Aborting.";
}

$result = system("chmod 644 $trusted_certs_dir/${ca_install_hash}.0");

if ($result != 0) 
{
  die "Failed to set permissions on $trusted_certs_dir/${ca_install_hash}.0. Aborting.";
}

#
# Install Globus CA policy file if not present
#
print "Installing Globus CA signing policy into trusted CA certificate directory...\n";

$result = system("cp $setupdir/${ca_install_hash}.signing_policy $trusted_certs_dir");

if ($result != 0) 
{
  die "Failed to install $trusted_certs_dir/${ca_install_hash}.signing_policy. Aborting.";
}

$result = system("chmod 644 $trusted_certs_dir/${ca_install_hash}.signing_policy");

if ($result != 0) 
{
  die "Failed to set permissions on $trusted_certs_dir/${ca_install_hash}.signing_policy. Aborting.";
}

$installed_cert_hash = get_hash(${trusted_certs_dir});

# check for already existing config files in grid-security
handle_config_file("grid-security.conf", "grid-security.conf.${ca_install_hash}", 
		   "${target_dir}", "${trusted_certs_dir}");
handle_config_file("globus-user-ssl.conf", "globus-user-ssl.conf.${ca_install_hash}", 
		   "${target_dir}", "${trusted_certs_dir}");
handle_config_file("globus-host-ssl.conf", "globus-host-ssl.conf.${ca_install_hash}", 
		   "${target_dir}", "${trusted_certs_dir}");

my @statres = stat "$globusdir/etc/globus_packages/globus_trusted_ca_${ca_install_hash}_setup/pkg_data_noflavor_data.gpt";

if($statres[4] != $EUID)
{
   ($EUID,$EGID) = ($statres[4],$statres[5]);
}
    
my $metadata = new Grid::GPT::Setup(package_name => "globus_trusted_ca_${ca_install_hash}_setup");

$metadata->finish();

print "$myname: Complete\n";

sub handle_config_file
{
    my $file = shift;
    my $globus_ca_file = shift;
    my $current_dir = shift;
    my $move_dir = shift;

    my $symlink_exists = eval { symlink("",""); 1 };
    die "ERROR: symbolic links not supported on this machine.\n" if( ! $symlink_exists );

    if ( ! -f "$current_dir/$file" || ! defined($installed_ca_hash) )
    {
	# if no config files in grid-security dir, make symlinks of
        # of Globus CA config files
	$opt_default = 1;
	check_default($file, $current_dir, $move_dir, 0);
    }
    else
    {
	if( ! ( -l "$current_dir/$file" ) )
	{
	    # if old grid-security config files are not symlinked
            # then move them to certificates dir and make symlinks
            # from them

	    system("cp -f $current_dir/$file $move_dir/$file.$installed_cert_hash");
	    die "ERROR: Can't copy $current_dir/$file to $move_dir/$file.$installed_cert_hash.\n" if(($? >> 8) > 0);
	    check_default($file, $current_dir, $move_dir, 1);
	}
	else
	{
	    check_default($file, $current_dir, $move_dir, 0);
	}
    }
}

sub check_default
{
    my $file = shift;
    my $current_dir = shift;
    my $move_dir = shift;
    my $dodefault = shift;

    if($opt_default)
    {
	system("rm -f $current_dir/$file");
	die "ERROR: Can't delete $current_dir/$file" if (($? >> 8) > 0);
	die "ERROR: Can't create symlink from $move_dir/$file.${ca_cert_hash} to  $current_dir/$file.\n"
	    if (! symlink("$move_dir/$file.${ca_install_hash}", "$current_dir/$file"));
    }
    elsif($dodefault)
    {
	system("rm -f $current_dir/$file");
	die "ERROR: Can't delete $current_dir/$file" if (($? >> 8) > 0);
	die "ERROR: Can't create symlink from $move_dir/$file.$installed_cert_hash to  $current_dir/$file.\n"
	    if (! symlink("$move_dir/$file.$installed_cert_hash", "$current_dir/$file"));
    }
}

sub get_hash
{
    my $tmp_dirname = shift;
    opendir HANDLE, $tmp_dirname;
    my @entries = readdir(HANDLE);
    closedir(HANDLE);
    
    my @ca_certs = ();
    
    for my $ent (@entries)
    {
	if($ent =~ /[0-9a-zA-Z]*\.0$/)
	{
	    unshift @ca_certs, $ent;
	}
    }
    
    if (scalar(@ca_certs) == 1)
    {
	my $h = shift @ca_certs;
	$h =~ /(.*)\.0/;
	return $1;
    }
    elsif(scalar(@ca_certs) > 1)
    {
	warn "\nWARNING:  Can't match the previously installed GSI configuration files\n" . 
	     "          to a CA certificate. For the configuration files ending in\n" .
	     "          \"00000000\" located in $tmp_dirname,\n" .
	     "          change the \"00000000\" extension to the hash of the correct\n" .
	     "          CA certificate.\n\n";
	return "00000000";
    }
    else
    {
	return undef;
    }
}

sub pod2usage 
{
  my $ex = shift;

  print "setup-gsi [

              -help

              -nonroot[=path] 
                 sets the directory that the security 
                 configuration files will be placed in.  
                 If no argument is given, the config files 
                 will be placed in \$GLOBUS_LOCATION/etc/
                 and the CA files will be placed in  
                 \$GLOBUS_LOCATION/share/certificates.

              -default
                 sets the Globus CA as the CA to be used
                 when generating certificate requests.  If
                 this option is not used, the Globus CA only
                 becomes the default if no other CA has already
                 been installed.
          ]\n";

  exit $ex;
}


# End