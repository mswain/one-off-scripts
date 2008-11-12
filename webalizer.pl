#!/usr/bin/perl
#
# 2005-12-08 Initial version -- Matthew A. Swain
#
use strict;

my $serverLogDir = "/apps/blah/tomcat4/logs";
my $logPrefix = "localhost_access.";
my $logSuffix = ".log";
my $tmpDir = "/home/ops/webalizer";
my $outDir = "/var/www/usage/npp";

my $scp = "/usr/bin/scp";
my $cat = "/bin/cat";
my $chmod = "/bin/chmod";
my $webalizer = "/usr/bin/webalizer";

my @hosts = (
      "host1", 
      "host2", 
      "host3" 
      );

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-86400);
$year+=1900;
$mon++;
my $yesterday = sprintf('%d-%02d-%02d',$year,$mon,$mday);
my @data;
my $logname = $logPrefix.$yesterday.$logSuffix;

for my $host (@hosts) {
#make directory structure for $host if they don't exist yet
   mkdir "$tmpDir/$host" if !(-d "$tmpDir/$host");
   mkdir "$outDir/$host" if !(-d "$outDir/$host");
   chmod(0755,"$outDir/$host");

   my $res = system("ssh $host test -e $serverLogDir/$logname");
   if (!$res) {
      system("$scp ops\@$host:$serverLogDir/$logname $tmpDir/$host/$logname");
      open (LF, "<$tmpDir/$host/$logname");
      push(@data,<LF>);
      close (LF);
      system("$webalizer -pq -n $host -t \"Usage Statistics for $host\" -D $tmpDir/dns_cache.db -o $outDir/$host $tmpDir/$host/$logname");

   } 
}
if (@data)
{
   open(LF,">$tmpDir/$logname");
   my %ts;

   for (@data) {
      my $logEntry = $_;
      $logEntry =~ m/\[(.+)\]/;
      my ($day, $month, $yttz) = split /\//, $1;
      my ($yt, $tz) = split /\s+/, $yttz;
      my ($year, $hour, $min, $sec) = split /:/, $yt;
      my $ts = $hour * 3600 + $min * 60 + $sec;
      $ts{$logEntry} = $ts;
   }
   print LF sort { $ts{$a} <=> $ts{$b}; } @data;
   close(LF);
   system("$webalizer -pq -n \" \" -t \"Usage Statistics for all hosts\" -D $tmpDir/dns_cache.db -o $outDir $tmpDir/$logname");
}
system("$chmod -R 0755 $outDir");
