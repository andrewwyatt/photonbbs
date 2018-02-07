#!/usr/bin/perl
#

$|=1;
$countdown=10;
chdir '/';
umask 0;
open (STDIN,'/dev/null');
open (STDERR,'>/dev/null');
defined($pid=fork) || die "Can not fork..";
exit if $pid;
setsid;
$PRCS=$$;
for (;;) {
  @data=`top -n 1 -b -i -H | grep -v -e ^[a-Z] -e PID | awk '{print \$9":"\$10":"\$1":"\$12}' | grep [0-9]`;
  foreach $item(@data) {
    chomp ($item);
    ($cpu,$mem,$pid,$name)=split(/:/,$item);
    if ($name =~/bbs/i) {
      $cpu =~s/\..*//;
      if ($cpu ge 40) {
        $pidtokill=$pid;
        if ($prevpidtokill =~/$pidtokill/) {
          $countdown=$countdown-1;
        }
        if ($countdown == 0) {
          system("logger local6.notice PHOTONBBS: Killed $name - $pid");
          kill 9,$pid;
          $countdown=5;
        }
        $prevpidtokill=$pidtokill;
      }
    }
  }
  sleep 3;
}
