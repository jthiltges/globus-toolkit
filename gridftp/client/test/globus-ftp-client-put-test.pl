#! /usr/bin/env perl

=head1 Simple Put Tests

Tests to exercise the "put" functionality of the Globus FTP client library.

=cut

use strict;
use POSIX;
use Test;
use FtpTestLib;

my $test_exec = $ENV{GLOBUS_LOCATION} . '/test/' . 'globus-ftp-client-put-test';
my @tests;
my @todo;

my $gpath = $ENV{GLOBUS_LOCATION};

if (!defined($gpath))
{
    die "GLOBUS_LOCATION needs to be set before running this script"
}

@INC = (@INC, "$gpath/lib/perl");

=pod

=head2 I<basic_func> (Test 1-2)

Do a simple put of $test_url. Compare the resulting file with the real file.

=over 4

=item Test 1

Transfer file without a valid proxy. Success if test program returns 1,
and no core dump is generated.

=item Test 2

Transfer file with a valid proxy. Success if test program returns 0 and
files compare.

=back

=cut
sub basic_func
{
    my ($use_proxy) = (shift);
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);

    unlink('core', $tmpname);

    if($use_proxy == 0)
    {
        FtpTestLib::push_proxy('/dev/null');
    }
    $rc = system("$test_exec -d 'gsiftp://localhost$tmpname' < /etc/group >/dev/null 2>&1") / 256;
    if(($use_proxy && $rc != 0) || (!$use_proxy && $rc == 0))
    {
        $errors .= "Test exited with $rc. ";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }
    if($use_proxy)
    {
    	my $diffs = `diff /etc/group $tmpname 2>&1 | sed -e 's/^/# /'`;

	if($diffs ne "")
	{
	    $errors .= "\n# Differences between /etc/group and output.";
	    $errors .= "$diffs";
	}
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
    unlink($tmpname);
    if($use_proxy == 0)
    {
        FtpTestLib::pop_proxy();
    }
}
push(@tests, "basic_func" . "(0);"); #Use invalid proxy
push(@tests, "basic_func" . "(1);"); #Use proxy


=pod

=head2 I<bad_url> (Test 3)

Do a simple put of a non-existent file.

=over 4

=item Test 3

Attempt to store a file to a bad path. Success if program returns 1
and no core file is generated.

=back

=cut
sub bad_url
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);

    unlink('core', $tmpname);

    $rc = system("$test_exec -d 'gsiftp://localhost/no/such/file/here' < /etc/group >/dev/null 2>/dev/null") / 256;
    if($rc != 1)
    {
        $errors .= "\n# Test exited with $rc.";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
    unlink($tmpname);
}
push(@tests, "bad_url");

=head2 I<abort_test> (Test 4-44)

Do a simple put of $test_url, aborting at each possible state in the plugin
state machine. Note that all abort states will be reached for the "put"
operation.

Success if no core ifle is generated for all abort points. (We could use
a stronger measure of success here.)

=cut
sub abort_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("", 0);
    my ($abort_point) = shift;

    unlink('core', $tmpname);

    $rc = system("$test_exec -a $abort_point -d 'gsiftp://localhost/$tmpname' </etc/group >/dev/null 2>/dev/null") / 256;
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
    unlink($tmpname);
}
for(my $i = 1; $i <= 41; $i++)
{
    push(@tests, "abort_test($i);");
}

=head2 I<restart_test> (Test 45-85)

Do a simple put to $test_url, restarting at each plugin-possible
point.  Compare the resulting file with the real file. Success if
program returns 0, files compare, and no core file is generated.

=cut
sub restart_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);
    my ($restart_point) = shift;

    unlink('core', $tmpname);

    $rc = system("$test_exec -r $restart_point -d 'gsiftp://localhost/$tmpname' < /etc/group >/dev/null 2>&1") / 256;
    if($rc != 0)
    {
        $errors .= "Test exited with $rc. ";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }
    my $diffs = `diff -u /etc/group $tmpname 2>&1 | sed -e 's/^/#/'`;
    if($diffs ne "")
    {
        $errors .= "\n# Differences between /etc/group and output.";
	$errors .= "$diffs"
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok("\n# $test_exec -r $restart_point\n#$errors", 'success');
    }
    unlink($tmpname);
}
for(my $i = 1; $i <= 41; $i++)
{
    push(@tests, "restart_test($i);");
}
push(@todo, 83);

=head2 I<dcau_test> (Test 86-89)

Do  a simple get of $test_url, using each of the possible DCAU modes,
including subject authorization iwth a bad subject name.

=over 4

=item Test 86

DCAU with no authorization.

=item Test 87

DCAU with "self" authorization.

=item Test 88

DCAU with subject authorization for our subject

=item Test 89

DCAU with subject authorization with an invalid subject.

=back

=cut
sub dcau_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);
    my ($dcau, $desired_rc) = @_;

    unlink('core');

    $rc = system("$test_exec -c $dcau -d 'gsiftp://localhost$tmpname' < /etc/group >/dev/null 2>&1") / 256;

    if($rc != $desired_rc)
    {
	$errors .= "Test exited with $rc. ";
    }

    if(-r 'core')
    {
	$errors .= "\n# Core file generated.";
    }

    if($errors eq "" && $desired_rc == 0)
    {
	my $diffs = `diff /etc/group $tmpname 2>&1 | sed -e 's/^/# /'`;

	if($diffs ne "")
	{
	    $errors .= "\n# Differences between /etc/group and output.";
	    $errors .= "$diffs";
	}
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
    unlink($tmpname);
}

chomp(my $subject = `grid-cert-info -subject`);

$subject =~ s/^ *//;

push(@tests, "dcau_test('none', 0);");
push(@tests, "dcau_test('self', 0);");
push(@tests, "dcau_test(\"'$subject'\", 0);");
push(@tests, "dcau_test(\"'/O=Grid/O=Globus/CN=bogus'\", 1);");

=head2 I<prot_test> (Test 90-92)

Do a simple get of $test_url, using DCAU self with clear, safe, and
private data channel protection.

=over 4

=item Test 90

PROT with clear protection

=item Test 91

PROT with safe protection

=item Test 92

PROT with private protection

=cut
sub prot_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);
    my ($prot, $desired_rc) = @_;

    unlink('core');

    $rc = system("$test_exec -c self -t $prot -d 'gsiftp://localhost$tmpname' < /etc/group >/dev/null 2>&1") / 256;

    if($rc != $desired_rc)
    {
	$errors .= "Test exited with $rc. ";
    }

    if(-r 'core')
    {
	$errors .= "\n# Core file generated.";
    }

    if($errors eq "" && $desired_rc == 0)
    {
	my $diffs = `diff /etc/group $tmpname 2>&1 | sed -e 's/^/# /'`;

	if($diffs ne "")
	{
	    $errors .= "\n# Differences between /etc/group and output.";
	    $errors .= "$diffs";
	}
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
    unlink($tmpname);
}

push(@tests, "prot_test('clear', 0);");
push(@tests, "prot_test('safe', 0);");
push(@tests, "prot_test('private', 0);");

=head2 I<perf_test> (Test 93)

Do a simple put of /etc/group, enabling perf_plugin

=back

=cut
sub perf_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);

    unlink('core');

    $rc = system("$test_exec -d 'gsiftp://localhost$tmpname' -M < /etc/group >/dev/null 2>&1") / 256;
    if($rc != 0)
    {
        $errors .= "Test exited with $rc. ";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok("\n# $test_exec -M\n#$errors", 'success');
    }
    unlink($tmpname);
}

push(@tests, "perf_test();");

=head2 I<throughput_test> (Test 94)

Do a simple put of /etc/group, enabling throughput_plugin

=back

=cut
sub throughput_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);

    unlink('core');

    $rc = system("$test_exec -d 'gsiftp://localhost$tmpname' -M -T < /etc/group >/dev/null 2>&1") / 256;
    if($rc != 0)
    {
        $errors .= "Test exited with $rc. ";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok("\n# $test_exec -T\n#$errors", 'success');
    }
    unlink($tmpname);
}

push(@tests, "throughput_test();");

=head2 I<restart_plugin_test> (Test 93-?)

Do a get of $test_url, triggering server-side faults, and using
the default restart plugin to cope with them.

=back

=cut
sub restart_plugin_test
{
    my $tmpname = POSIX::tmpnam();
    my ($errors,$rc) = ("",0);
    my $other_args;

    unlink('core');

    $ENV{GLOBUS_FTP_CLIENT_FAULT_MODE} = shift;
    $other_args = shift;
    if(!defined($other_args))
    {
	$other_args = "";
    }

    $rc = system("$test_exec -d 'gsiftp://localhost$tmpname' -f 0,0,0,0 $other_args < /etc/group >/dev/null 2>&1") / 256;
    if($rc != 0)
    {
        $errors .= "Test exited with $rc. ";
    }
    if(-r 'core')
    {
        $errors .= "\n# Core file generated.";
    }
    $errors .= FtpTestLib::compare_local_files('/etc/group', $tmpname);

    if($errors eq "")
    {
        ok('success', 'success');
    }
    else
    {
        ok($errors, 'success');
    }
        delete $ENV{GLOBUS_FTP_CLIENT_FAULT_MODE};
    unlink($tmpname);
}
foreach (&FtpTestLib::ftp_commands())
{
    push(@tests, "restart_plugin_test('$_');");
}
push(@tests, "restart_plugin_test('PROT', '-c self -t safe')");
push(@tests, "restart_plugin_test('DCAU', '-c self -t safe')");
push(@tests, "restart_plugin_test('PBSZ', '-c self -t safe')");



# Now that the tests are defined, set up the Test to deal with them.
plan tests => scalar(@tests), todo => \@todo;

# And run them all.
foreach (@tests)
{
    eval "&$_";
}
