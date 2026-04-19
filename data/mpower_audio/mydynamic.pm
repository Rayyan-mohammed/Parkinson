package myDynamic;
#This script was modified from Parallel::Simple::Dynamic

use Class::Std;
use Class::Std::Utils;
use POSIX qw(ceil);
use Parallel::Simple qw(prun);
use Bio::SeqIO;
use PBS::Client;
use Cwd;
use Data::Dumper;

use version; 
our $VERSION = qv('0.0.4');
use warnings; 
use strict;

{
        my %list_of  		:ATTR( :get<list>   	     :set<list>   	   :default<[]>    :init_arg<list> );
        my %call_back		:ATTR( :get<call_back>       :set<call_back>       :default<''>    :init_arg<call_back> );
        my %num_of_cores	:ATTR( :get<num_of_cores>    :set<num_of_cores>    :default<''>    :init_arg<num_of_cores> );

	sub START {
		my ($self, $ident, $arg_ref) = @_;
		return;
	}
	
	sub drun {
		my ( $self, $arg_ref ) = @_;
	
		my $parts        =  defined $arg_ref->{parts}	     ? $arg_ref->{parts}        : 2;
		my $list         =  defined $arg_ref->{list} 	     ? $arg_ref->{list}   	:[];
		my $call_back	 =  defined $arg_ref->{call_back}    ? $arg_ref->{call_back} 	:'';

		my @partitions = $self->partition( {parts => $parts, list => $list } );

		my ( $pindex, @prun );
		foreach my $partition ( @partitions ) {
		        my $prun = [ $call_back, ++$pindex, @$partition ];
			push @prun, $prun;
			}
		#prun( @prun, { use_return => 1 } ) or die( Parallel::Simple::errplus() );
		prun( @prun ) or die( Parallel::Simple::errplus() );
		#return (Parallel::Simple::rv());
	}	
	
	sub partition {
		my ( $self, $arg_ref ) = @_;
		
		my $parts =  defined $arg_ref->{parts} ? $arg_ref->{parts} : 2;
		my $list  =  defined $arg_ref->{list}  ? $arg_ref->{list}  : [];
		my @results;
		my @segments = $self->calc_segments( {parts => $parts, list_length => scalar( @$list )} );
		for ( my $i = 1; $i <= $parts; $i++ ) {
			my $start   = $segments[$i-1];
			my $end     = $segments[$i] - 1;
			my @segment = @$list[$start..$end];
			push @results, \@segment;
		}
		return @results;
	}
	
	sub calc_segments {
		my ( $self, $arg_ref ) = @_;
		
		my $parts        =  defined $arg_ref->{parts}	     ? $arg_ref->{parts}        : 2;
		my $list_length  =  defined $arg_ref->{list_length}  ? $arg_ref->{list_length}  :'';
		my @segments = (0);
		my $width   = $list_length / $parts;
		for ( my $i = 1; $i <= $parts; $i++ ) {
			$segments[$i] = ceil( ($i) * $width );
		}
		return @segments;
	}
}

sub check_pbs {
	my $tfile = shift;
#	my %pbs_state = (
#	'state.notfound.regexp' => 'Unknown Job Id',
#	"state.pend.regexp" => "\d+ (H|Q|T|W|S) \w+",
#	"state.run.regexp" => "\d+ (R) \w+",
#	"state.done.regexp" => "\d+ (C|E) \w+"
#	);	
	my $state = 0;
	#print Dumper %pbs_state;
	while($state == 0){
		my $tail = `tail -n 1 $tfile` if (-r $tfile);
		#print "$tail \n";
		if ($tail && $tail =~/^FINISH|^RUNTIME/) {
			$state = 1;
		}
		sleep 3;
	}
	return 0;
}

sub slurm_start {
	my $job_para = shift;
	my $rand_d1 = int(rand(1000));
	my $rand_d2 = int(rand(1000));
	my $rand_d = $rand_d1 . $rand_d2;
	my $infile = $rand_d . ".sh." . $job_para->{'queue'}; #temp parameter file for commands
	my %job_para_slurm;
	$job_para_slurm{'procs'} = $job_para->{'procs'} || 8;
	$job_para_slurm{'cpus_per_task'} = $job_para->{'ppn'} || 1;
	$job_para_slurm{'walltime'} = $job_para->{'wallt'} || "6-12:30:00";
	$job_para_slurm{'partition'} = $job_para->{'queue'} || "general";
	$job_para_slurm{'use_processes'} = $job_para->{'ppn'} || 1;
	$job_para_slurm{'mem'} = $job_para->{'pmem'} || 20000;
	#$job_para_slurm{'nodes_count'} = $job_para{'ppn'} || 1;
	$job_para_slurm{'jobname'} = $rand_d;
	if (defined $job_para->{'nodes'}) {
		#so far, no use in slurm system to specify nodes.
		$job_para_slurm{'nodes'} = $job_para->{'nodes'};
	}

	#print Dumper $job_para->{"cmd"};
	#print "$comm\n";
	#die;
	if (!defined $job_para->{'infile'} and defined $job_para->{'cmd'})
	{
		$job_para_slurm{'infile'} = $infile; #new parameter hash
		open IN, ">$infile" or die $!;
		my $num = 1;
		my $comm = shift @{$job_para->{"cmd"}};
		my @comms = split /;|\n/, $comm;
		@comms = grep {/\S/} @comms;
		for (@comms)
		{
			print IN "$_\n";
			print IN "wait\n" if ($num < @comms);
			$num++;
		}
		close IN;
	} else {
		if (-s $job_para->{'infile'}) 
		{
			$job_para_slurm{'infile'} = $job_para->{'infile'};
		} else {
			die "$job_para->{'infile'} NOT exists";
		}
	}
#die;
	#package Main;
	#use Moose;
	#extends 'HPC::Runner::Slurm';
	#myDynamic->new_with_options->run;
	#Main->new_with_options(
	#	\%job_para_slurm
	#);
	#Main->submit_slurm();
	#use Data::Dumper;
	#print Dumper $ret;
	#die;
	#
	my $jobid_s = `slurmrunner.pl --infile $job_para_slurm{'infile'} --walltime $job_para_slurm{'walltime'} --cpus_per_task $job_para_slurm{'cpus_per_task'} --mem $job_para_slurm{'mem'} --procs $job_para_slurm{'procs'} --partition $job_para_slurm{'partition'} --use_processes $job_para_slurm{'use_processes'} --jobname $job_para_slurm{'jobname'}`;
	my $jobid = $1 if ($jobid_s=~/Slurm jobid (\d+)/);
	#print "ID: $jobid\n";
	unlink $infile if ($job_para_slurm{'infile'} eq $infile);	
	return ($jobid);
}

sub pbs_start {
	my $dir = shift;
	my $comm = shift;
	my $queue = shift;
	my $max_q_num = shift || 30;
	my $sleep_time = shift || 15;
	my $max_r_num = shift || 305;
	my $max_sleep_time = shift || 60;
	my $pmem = shift || undef;
	my $ppn = shift || undef;
	my $wallt = shift || undef;
	my $nodes = shift || undef;
	my $HPC_system = shift || "slurm"; #!!!the default HPC manage system changed here, from original PBS to Slurm
	if ($comm eq "") {
		die "Commands has not to be empty.";
	}

	if (!$queue) {
		#$queue = ($HPC_system eq "slurm") ? "scavenge" : "default";
		$queue = ($HPC_system eq "slurm") ? "general" : "default";
	}
	my $paths=getcwd;
	my @tempcmd= ($comm);
	my %job_para = (
		wd        => $paths,
		script    => "$dir.sh",
		efile     => "$dir.efile",
		ofile     => "$dir.ofile",
		queue     => $queue,
		pmem      => $pmem,
		ppn       => $ppn,
		wallt 	  => $wallt,
		nodes 	  => $nodes,
		cmd   	  => \@tempcmd
	);
	#deleting empty parameters
	for my $k (keys %job_para)
	{
		if (!$job_para{$k}) {
			delete $job_para{$k};
		}
	}
	
	my @pbs_monitor_para = ($queue, $max_q_num, $sleep_time, $max_r_num, $max_sleep_time);
	if ($HPC_system eq "pbs")
	{
		#&check_pbs_qstat($queue, $max_q_num, $sleep_time, $max_r_num, $max_sleep_time);
		&check_pbs_qstat(\@pbs_monitor_para);
		my @tempcmd=[$comm,"JOBID=`echo \$PBS_JOBID | sed -e 's/\\..*\$//'`","shfile=$dir.sh.\${JOBID}"];
		$job_para{"cmd"} = \@tempcmd;
		my $client = PBS::Client->new();
		my $job;
		$job = PBS::Client::Job->new(
			%job_para
		);
		#use Data::Dumper;
		#print Dumper $nodes;
		#print Dumper %job_para;
		$client->qsub($job);
		print STDERR "PBS failed. ($@)" if ($@);
		my $jobids=$job->pbsid;
		my @tempjobid=@{$jobids};
		print STDERR "PBS job assigned. Job id: @tempjobid, Queue: $queue. \n";
		return @tempjobid;
	} elsif ($HPC_system eq "slurm") {
		#&check_slurm_stat($queue, $max_q_num, $sleep_time, $max_r_num, $max_sleep_time);
		&check_slurm_stat(\@pbs_monitor_para);
		my $jobids = &slurm_start(\%job_para);
		my @tempjobid= ($jobids);
		print STDERR "PBS job assigned. Job id: @tempjobid, Queue: $queue. \n";
		return @tempjobid;
	}
}

sub check_slurm_stat {
	#to avoid to many Slurm jobs
	#before sumit to Slurm, check the queue numbers. 
	my $pbs_monitor_para = shift;
	my @pbs_monitor_para = @{$pbs_monitor_para};
	my $queue = $pbs_monitor_para[0];
	my $max_q_num = $pbs_monitor_para[1];
	my $sleep_time = $pbs_monitor_para[2];
	my $max_r_num = $pbs_monitor_para[3];
	my $max_sleep_time = $pbs_monitor_para[4];

	while (1) {
		if (0) {
			#the original code, obsolete, 09/24/2017
			my $CMD = qq/squeue -u $ENV{USER} -p $queue |  gawk '\$5=="R" {print}' | wc -l/;
			my @res = split /\n/, `$CMD`;
			my $num_R = $res[0];
			$CMD = qq/squeue -u $ENV{USER} -p $queue |  gawk '\$5=="PD" {print}' | wc -l/;
			@res = split /\n/, `$CMD`;
			my $num_Q = $res[0];
		}

		my $CMD = qq/sacct -o "Jobid,Partition,State,ReqTRES%32" | grep $queue | grep RUNNING/;
		my @res = split /\n/, `$CMD`;
		my $num_R = 0;
		for my $r (@res) {
			if ($r=~/cpu=(\d+),/){
				$num_R = $num_R + $1;
			}
		}
		$CMD = qq/sacct -o "Jobid,Partition,State,ReqTRES%32" | grep $queue | grep PENDING | wc -l/;
		my $num_Q = `$CMD`;
		chomp ($num_Q);
		if ($num_Q < $max_q_num && $num_R < $max_r_num) {
			return (1);
		} else {
			sleep $sleep_time;
			$sleep_time += $sleep_time if ( $sleep_time < $max_sleep_time ); #at most sleep 15 min	
		}
	}
}

sub check_pbs_qstat{
	#to avoid to many PBS jobs
	#before sumit to pbs, check the queue numbers. 
	my $pbs_monitor_para = shift;
	my @pbs_monitor_para = @{$pbs_monitor_para};
	my $queue = $pbs_monitor_para[0];
	my $max_q_num = $pbs_monitor_para[1];
	my $sleep_time = $pbs_monitor_para[2];
	my $max_r_num = $pbs_monitor_para[3];
	my $max_sleep_time = $pbs_monitor_para[4];

	while (1) {
		my $CMD = qq/qstat -au $ENV{USER} | grep $queue/;
		my @res = split /\n/, `$CMD`;
		my $num_Q = 0;
		my $num_R = 0;
		for my $c (@res) {
			if ($c=~/ R /) {
				$num_R++;
			} elsif ($c=~/ Q /) {
				$num_Q++;
			}
		}
		if ($num_Q < $max_q_num && $num_R < $max_r_num) {
			return (1);
		} else {
			sleep $sleep_time;
			$sleep_time += $sleep_time if ( $sleep_time < $max_sleep_time ); #at most sleep 15 min	
		}
	}
}

sub check_pbs_status
{
	my (@pbsids) = @_;
	my $HPC_system = "slurm"; #!!! change if the default HPC system is not slurm
	if ($HPC_system eq "pbs") {
		&check_pbs_status_pbs(@pbsids);
	} elsif ($HPC_system eq "slurm")
	{
		&slurm_status(@pbsids);
	}

}

sub slurm_status
{
	my (@pbsids) = @_;
	my $wait_factor = 15; #waiting seconts for each unfinished process
	my $wait_time = 10;
	my $max_sleep_time = 300;
	while(@pbsids>0){
		sleep $wait_time;
		my @temp;
		for(my $i=0;$i<@pbsids;$i++){
			my $tt=`squeue --job $pbsids[$i] | gawk 'NR!=1{print \$5}'`;
			#	print "TT: $tt\n";
			if($tt ne 'CG' and $tt ne 'CD' and $tt ne "")
			{
				push @temp,$pbsids[$i];
			}
		}
		@pbsids=@temp;
		my $num = @pbsids;
		$wait_time = $num * $wait_factor;
		$wait_time = ($wait_time > $max_sleep_time) ? $max_sleep_time : $wait_time 
		#$sleep_time += $wait_time if ( $sleep_time < $max_sleep_time ); #at most sleep 5 min
	}
	print STDERR "All PBS jobs have been done. \n";
	return 0;
}

sub check_pbs_status_pbs
{
	my (@pbsids) = @_;
	my $wait_factor = 15; #waiting seconts for each unfinished process
	my $wait_time = 15;
	my $max_sleep_time = 300;
	while(@pbsids>0){
		sleep $wait_time;
		my @temp;
		for(my $i=0;$i<@pbsids;$i++){
			my $tt=`qstat -f $pbsids[$i]`;
			if($tt =~ /job_state = ([A-Z])/){
				$tt=$1;
				if($tt ne 'C')
				{
					push @temp,$pbsids[$i];
				}
			}
		}
		@pbsids=@temp;
		my $num = @pbsids;
		$wait_time = $num * $wait_factor;
		$wait_time = ($wait_time > $max_sleep_time) ? $max_sleep_time : $wait_time 
		#$sleep_time += $wait_time if ( $sleep_time < $max_sleep_time ); #at most sleep 5 min
	}
	print STDERR "All PBS jobs have been done. \n";
	return 0;
}

sub split_fasta {
	my ($inputSeq,$CPU_num) = @_;
	my $D;
	my $in  = Bio::SeqIO->new(-file => $inputSeq , -format => 'Fasta');
	my $n = 0;

	#added by Zxy for randomly select sequences
	my $D1 = {};
	while ( my $seq = $in->next_seq() ) {
		my $id = $seq->id . " " . $seq->desc;
		#$D->[$n] = [$id,$seq->seq];
		$D1->{$n} = [$id,$seq->seq];
		$n++;
	}

	$n = 0;
	for my $j (keys %$D1) {
		$D->[$n] = $D1->{$j};
		$n++;
	}
	undef $D1;

	#print Dumper $D;
	print STDERR "     in total $n sequences. \n";
	#die;
	if ($CPU_num > $n) {
		print STDERR "\nError: \nCPU num is more than sequence num. Please set a less digit as cpu argument. \n\n";
		exit 1;
	}	
	return $D;
}

sub split_fasta_2 {
	my ($inputSeq,$CPU_num) = @_;
	my $D;
	my $n = 0;
	my $D1 = {};
	#my $in = shift;
	#my $seq_out = "aa.fas";
	open IN, $inputSeq;
	local $/ = ">"; # entire input to be read in one slurp

	#my $seqs = <IN>;  # read input, assigning to single string
	#print Dumper $seqs;
	#die;
	while (<IN>){
		next if $. == 1;
		chomp;
		my @l = split /\n/, $_;
		my $id = $l[0];
		my $seq;
		for my $i (1..$#l) {
			$seq .= $l[$i];
		}
		$D1->{$n} = [$id,$seq];
		$n++;		

	}
	close(IN);
	$n = 0;
	for my $j (keys %$D1) {
		$D->[$n] = $D1->{$j};
		$n++;
	}
	undef $D1;

	#print Dumper $D;
	print STDERR "     in total $n sequences. \n";
	#die;
	if ($CPU_num > $n) {
		print STDERR "\nError: \nCPU num is more than sequence num. Please set a less digit as cpu argument. \n\n";
		exit 1;
	}	
	return $D;	
}

sub parse_pbs_config {
	my $pbs_config_f = shift;
	die ("Not a valid file: $pbs_config_f") if (!-f $pbs_config_f);
	my %pbs_config;
	if (-s $pbs_config_f) {
		open CON, $pbs_config_f or die $!;
		while (<CON>) {
			chomp;
			my @l = split /\t/, $_;
			$pbs_config{$l[0]} = $l[1] if ($l[0]=~/\S/ && $l[1] >= 0);
		}
		close CON;
	}
	return (\%pbs_config);
}

1; 
