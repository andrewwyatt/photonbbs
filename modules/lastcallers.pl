#!/usr/bin/perl


sub lastcallers{
  if ($config{'lastcallenable'} ne "0") {
    chomp ($ctime=`date +\%H:\%M`);
    chomp ($cdate=`date +\%Y-\%h-\%d`);
    if (-e "$config{'home'}$config{'text'}/lastcallers") {
      if (-e "$config{'home'}$config{'text'}/lastcalltop.$info{'ext'}") {
	writeline("\n");
        readfile("lastcalltop.$info{'ext'}");
      } else {
        writeline($theme{'lastcalltopa'},1);
        writeline($theme{'lastcalltopb'},1);
      }
      readfile("lastcallers");
      if (-e "$config{'home'}$config{'text'}/lastcallbot.$info{'ext'}") {
        readfile("lastcallbot.$info{'ext'}");
      } else {
        writeline($theme{'lastcallbot'},1);
      }
      unless ($_[0] =~/nopause/) {
        pause();
      }

    } else {
      writeline($theme{'lastcallemp'},1);
    }
      open (in,"<$config{'home'}$config{'text'}/lastcallers");
        @lastcalls=<in>;
      close(in);
      $lastkeep=$config{'lastcallers'};
      --$lastkeep;
      unless (scalar(@lastcalls) <= $lastkeep) {
        until (scalar(@lastcalls) <= $lastkeep || scalar(@lastcalls) <= 0) {
          $junk=shift(@lastcalls);
        }
      }
      $didcall=0;
      open (lastcallers,">$config{'home'}$config{'text'}/lastcallers");
      foreach $caller(@lastcalls) {
        if ($caller=~/$info{'handle'}/i) {
          next;
        }
        print lastcallers $caller;
      }
      close (lastcallers);

      $ctime=$ctime;
      unless ($didcall eq 1) {
format lastcallers =
@<<<<<<< @<<<<<<<<<<<<<<<  .....  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$ctime,$whouser,$whowhere
.
        open (lastcallers,">>$config{'home'}$config{'text'}/lastcallers");
         $~="lastcallers";
         $whouser=$info{'handle'};
         $whowhere=$info{'location'};
         write lastcallers;
         $~="stdout";
        close (out);
      }
    }
    #undef %lastcalls;
  }
return 1;
