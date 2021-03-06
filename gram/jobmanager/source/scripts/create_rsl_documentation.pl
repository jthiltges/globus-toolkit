#! /usr/bin/env perl

if ($ARGV[0] eq '-x')
{
    shift(@ARGV);
    %values = &read_input();
    &print_xml(%values);
}
elsif ($ARGV[0] eq '-a')
{
    shift(@ARGV);
    %values = &read_input();
    &print_asciidoc(%values);
}
else
{
    %values = &read_input();
    &print_html(%values);
}

sub print_html
{
    print <<EOF;
/* this page was automatically generated by $0 */

/**
\@page globus_gram_job_manager_rsl RSL Attributes

This page contains a list of all RSL attributes which are supported
by the GRAM Job Manager.

EOF

    foreach(sort keys %values)
    {
	my $shortname;
	$shortname = lc($_);
	$shortname =~ s/_//g;
	next if($values{$_}{Publish} eq "false");
	print <<EOF;

\@anchor globus_gram_rsl_attribute_$shortname
\@par $_
$values{$_}{Description}
EOF
    }
    print <<EOF;
*/
EOF
}

sub print_xml
{
    print <<EOF;
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE refentry PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN" "http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">

<!-- Canonical version of this document lives in 
\$Header\$

This document was automatically generated by $0
-->

<refentry>
<refmeta>
<refentrytitle>rsl</refentrytitle>
<manvolnum>5</manvolnum>
<refmiscinfo class="author">University of Chicago</refmiscinfo>
</refmeta>

<refnamediv>
<refname>rsl</refname>
<refpurpose>GRAM5 RSL Attributes</refpurpose>
</refnamediv>

<refsect1><title>Description</title>
<para>
<variablelist>
EOF
    foreach(sort keys %values)
    {
	my $shortname;
	my $default_value = "";
	$shortname = lc($_);
	$shortname =~ s/_//g;
	next if($values{$_}{Publish} eq "false");
        if (exists $values{$_}{Default})
        {
            $default_value = " [Default: <literal>" . $values{$_}{Default} . "</literal>]";
        }
	print <<EOF;

    <varlistentry>
        <term><literal>$_</literal></term>
        <listitem><simpara>$values{$_}{Description}$default_value</simpara></listitem>
    </varlistentry>
EOF
    }

print <<EOF;
</variablelist>
</para>
</refsect1>
</refentry>
EOF
}

sub print_asciidoc
{
    print <<EOF;
RSL(5)
======
:doctype:      manpage
:man source:   Globus Toolkit
:man version:  6
:man manual:   Globus Toolkit Manual
:man software: Globus Toolkit

NAME
----
rsl - GRAM5 RSL Attributes

DESCRIPTION
-----------
EOF
    foreach(sort keys %values)
    {
	my $shortname;
	my $default_value = "";
	$shortname = lc($_);
	$shortname =~ s/_//g;
	next if($values{$_}{Publish} eq "false");
        if (exists $values{$_}{Default})
        {
            $default_value = " [Default: <literal>" . $values{$_}{Default} . "</literal>]";
        }
	print <<EOF;

*$_*::
    $values{$_}{Description}$default_value
EOF
    }

    print <<EOF;

AUTHOR
------
Copyright (C) 1999-2016 University of Chicago
EOF
}


sub read_input
{
    my %result;
    my $record = "";

    while(<>)
    {
	s/#.*//;

	if($_ ne "\n")
	{
	    $record .= $_;
	}
	else
	{
	    &insert_record(\%result, $record);
	    $record = "";
	}
    }
    &insert_record(\%result, $record);

    return %result;
}

sub insert_record
{
    my $hash = shift;
    my $data = shift;
    my %result;
    my $attribute;
    my $value;
    my $in_multiline = 0;

    foreach (split(/\n/, $data))
    {
	if($in_multiline)
	{
	    $value .= $_;
	    if($value =~ m/[^\\]"/)
	    {
		$value =~ s/\s+/ /g;
		$in_multiline = 0;
		$value =~ s/\\"/"/g;
		$value =~ s/^"//;
		$value =~ s/"$//;
	    }
	    else
	    {
		next;
	    }
	}
	else
	{
	    ($attribute, $value) = split(/:/, $_, 2);

	    if($value =~ m/^\s*".*[^"]$/)
	    {
		# multiline value
		$in_multiline = 1;
	    }
            elsif ($value =~ m/^\s*"[^"]*"$/)
            {
                $value =~ s/^\s*"/ /;
                $value =~ s/"$//;
            }
	    $value =~ s/^\s*//;
	    if($in_multiline)
	    {
		if($value =~ m/[^\\]"/)
		{
		    $value =~ s/\s+/ /g;
		    $in_multiline = 0;
		    $value =~ s/\\"/"/g;
		    $value =~ s/^"//;
		    $value =~ s/"$//;
		}
	    }
	}
	$result{$attribute} = $value;
    }

    $attribute = $result{Attribute};

    foreach (keys %result)
    {
	$hash->{$attribute}{$_} = $result{$_};
    }
}
