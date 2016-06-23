#!/usr/bin/perl -w
use strict;
use warnings;
use File::Spec;
use Getopt::Long;

my ($bam_in, $total, $res, $out);
GetOptions(
	'bam_in:s'	=>	\$bam_in,
	'res:s'		=>	\$res,
	'out:s'		=>	\$out,
	'h|help:s'	=>	\&usage,
);

&usage if (not $bam_in or not $res or not $out);
chomp ($total = `du -shm $bam_in | cut -f 1`);
my @res = split/\,/,$res;
my @out = split/\,/,$out;

die ("wrong number") if ($#res<0 && $#res != $#out);
map {die ("wrong res size") if ($_ > $total)} @res;

my %out;
for (my $n=0;$n<=$#out;$n++){
	open ($out{$res[$n]},"|samtools view -Sb - > $out[$n]");
}
@res=sort{$b<=>$a}keys(%out);

open (INP,"samtools view -h $bam_in | ");
while (<INP>){
	if ($_ =~ /^\@/){
		for my $res (@res){
			my $fh = $out{$res};
			print $fh $_;
			}
		next;
		}
	my $number = rand($total);
	for $res(@res){
		if ($number < $res){
			my $fh = $out{$res};
			print $fh $_;
		}else{
			last;
		}
	}
}
close(INP);
map {`samtools index $_`} @out;

sub usage{
	print STDERR << "EOF";
	usage:[-bam_in -total -res -out]
	-h:			:help
	-bam_in:		:bam file
	-res:			:residual size
	-out:			:out bam file

	example:
	perl $0 -bam_in ./IonXpress_060_rawlib.bam -res 100 -out ./100_rawlib.bam
	perl $0 -bam_in ./IonXpress_060_rawlib.bam -res 100,200 -out ./100.bam,./200.bam
EOF
exit(1);
}
