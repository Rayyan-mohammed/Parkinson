#!/usr/bin/env perl
#used for Getopt::long parameters
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use Time::SoFar qw( runtime runinterval figuretimes);
use PBS::Client;
use File::Path;
use Cwd;
use FindBin qw($RealBin);
use lib $RealBin . "/lib";
use myDynamic;

my $help;
my $queue 			= "bigmem";
my $nodes 			= undef;
my $max_q_num 		= 50;
my $sleep_time 		= 60;
my $max_r_num 		= 1000; 
my $max_sleep_time 	= 600;
#my $wallt		 	= "240:00:00"; # is for PBS
my $wallt		 	= "6-22:30:00"; #slurm: 5 day 12.5 hour
my $ifemail;
my $pmem			= 20000; #slurm: 20G
my $ppn				= 1;
my $pbs_config_f;
my $SYSTEM 			= "slurm"; #slurm/pbs
my $infile; #used in slurm system, including commands
my $procs			= 8;

my $script = basename($0);
my $taxpath = $ENV{PWD};
my $dir = $$;

GetOptions(
	'h'         =>  \$help,
	'e'         =>  \$ifemail,
	'i|infile=s' =>  \$infile,   	#<string>, commands file name, including commands in slurm format (wait ...)
										#only used in slurm system
	'q|queue=s' =>  \$queue,   		#<bigmem/general>, PBS queue selection, DF: bigmem
	'n|nodes=s' =>  \$nodes,   		#<nodes>, PBS nodes name, DF: undef
	'qn=s'		=>  \$max_q_num, 	#<int>, Maximum queue number. DF: 30
	'sn=s'		=>  \$sleep_time,	#<int>, initial sleeping time. DF: 60
	'rn=s'		=>  \$max_r_num,	#<int>, Maximum running number. DF: 305
	'st=s'		=>  \$max_sleep_time,#<int>, Maximum sleeping time. DF: 600
	'proc=s'	=>  \$procs,		#<int>, procs para in slurm, DF: 8
	'wt=s'		=>  \$wallt,		#<string>, Maximum wall time. DF: 5-12:00:00 (5.5 days)
	'pmem=s'	=>  \$pmem,			#<int> (Mb), pmem para, maximum memory plan to use, DF: 20000
	'sys=s'		=>  \$SYSTEM,		#<slurm/pbs>, HPC manager system, DF: slurm
    'b|pbs=s'	=>  \$pbs_config_f, #file to configure the pbs parameters
									#!!if specified, all the parameter will be read from the file
	'ppn=s'		=>  \$ppn			#<int>, ppn para, how many threads per process plan to use, DF: 1
);

my @comms = @ARGV;
my $comm = join ";\n", @comms;
if ($ifemail) {
	my $pwd = `pwd`;
	chomp ($pwd);
	push @comms, 'echo "Commands have been done:  || ' 
. $comm 
. ' || '
. 'Working path: || '
. $pwd
. '" |  mutt -s "Commands finished!" -- xinyu.zhang@yale.edu';
}
$comm = join ";\n", @comms;

$comm = "-h" if (!$infile && !$comm);

if ($comm eq '-h') {
	print "
##############################
#Usage:
#Used to submit a task to PBS queue
##############################
	'h'         =>  \$help,
	'e'         =>  \$ifemail,
	'i|infile=s' =>  \$infile,   	#<string>, commands file name, including commands in slurm format (wait ...)
										#only used in slurm system
	'q|queue=s' =>  \$queue,   		#<bigmem/general>, PBS queue selection, DF: bigmem
	'n|nodes=s' =>  \$nodes,   		#<nodes>, PBS nodes name, DF: undef
	'qn=s'		=>  \$max_q_num, 	#<int>, Maximum queue number. DF: 30
	'sn=s'		=>  \$sleep_time,	#<int>, initial sleeping time. DF: 60
	'rn=s'		=>  \$max_r_num,	#<int>, Maximum running number. DF: 305
	'st=s'		=>  \$max_sleep_time,#<int>, Maximum sleeping time. DF: 600
	'proc=s'	=>  \$proce,		#<int>, procs para in slurm, DF: 8
	'wt=s'		=>  \$wallt,		#<string>, Maximum wall time. DF: 5-12:00:00 (5.5 days)
	'pmem=s'	=>  \$pmem,			#<int> (Mb), pmem para, maximum memory plan to use, DF: 20000
	'sys=s'		=>  \$SYSTEM,		#<slurm/pbs>, HPC manager system, DF: slurm
    'b|pbs=s	=>  \$pbs_config_f, #file to configure the pbs parameters
									#!!if specified, all the parameter will be read from the file
	'ppn=s'		=>  \$ppn			#<int>, ppn para, how many threads per process plan to use

Example: 
	pbsv2.pl \"plink19 --file hwe6 --recode --make-bed --out test\" -q bigmem -pmem 30 -ppn 4
	pbsv2.pl -i comm.sh

Notice:
	-b 	will specify a configuration file (e.g. ~/pbs.config)
		will cause other parameters expired. 
";
	exit 1;
}

if ($SYSTEM eq "pbs")
{
	if ($pmem =~/^\d+$/ && $pmem !~/gb$/) {
		$pmem = $pmem. "gb";
	}
}

my $nodesname = $nodes;
if ($nodesname)
{
	$nodesname = [$nodes];
}

my %pbs_config;
if (-s $pbs_config_f) {
	open CON, $pbs_config_f or die $!;
	while (<CON>) {
		chomp;
		my @l = split /\t/, $_;
		$pbs_config{$l[0]} = $l[1] if ($l[0]=~/\S/ && $l[1] >= 0);
	}
	close CON;
	($max_q_num,$sleep_time,$max_r_num,$max_sleep_time,$pmem,$ppn, $wallt) = ($pbs_config{'max_q_num'}, $pbs_config{'sleep_time'}, $pbs_config{'max_r_num'}, $pbs_config{'max_sleep_time'}, $pbs_config{'pmem'}, $pbs_config{'ppn'}, $pbs_config{'wallt'});
}

if(chdir("$taxpath"))
{
	if ($infile and -s $infile)
	{
		if ($SYSTEM eq "slurm")
		{
			$ppn = 8 if ($ppn == 1); #for infile mode, each task allocating 8 threads automatically
			my @pbs_monitor_para = ($queue, $max_q_num, $sleep_time, $max_r_num, $max_sleep_time);
			&myDynamic::check_slurm_stat(\@pbs_monitor_para);
			my %job_para = (
				wd        => $taxpath,
				queue     => $queue,
				pmem      => $pmem,
				ppn       => $ppn,
				wallt     => $wallt,
				procs	  => $procs,
				infile	  => $infile
			);
			my $jobids = &myDynamic::slurm_start(\%job_para);
			my @tempjobid= ($jobids);
			print "@tempjobid\n";
		} else {
			die "Infile (-i|-infile) only supports slurm system.";
		}
	} else {
		my @tempjobid  = myDynamic::pbs_start($dir,$comm,$queue,$max_q_num,$sleep_time,$max_r_num,$max_sleep_time,$pmem,$ppn, $wallt, $nodesname, $SYSTEM);
		print "@tempjobid\n";
	}
}
