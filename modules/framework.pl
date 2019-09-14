#!/usr/bin/perl
#
#  Photon BBS Framework
#  (C) 2002-2013 Andrew Wyatt

sub doevents {
  $currenttime=time;
  $idletime=$currenttime-$idle;
  $idlenotifycheck=$config{'idledisconnect'}/2;
  if ($idletime >= $idlenotifycheck) {
    if ($idlenotified eq 0) {
      writeline($config{'errorcolor'}."\e[s\nWarning: Your session will be disconnected in ".$idlenotifycheck." seconds due to inactivity.\e[u");
      $idlenotified=1;
    }
  }
  if ($idletime >= $config{'idledisconnect'}) {
    errorout("idle session terminated.");
  }
  $cppid = getppid;
  if ($ppid != $cppid) {
    errorout("parent process died, terminating.");
  }
  if ($atmenu eq "1") {
    unless ($noevents eq "1") {
      getpages();
    }
  }
}

sub usersonline {
  @userlst=<$config{'home'}$config{'nodes'}/*>;
  $sysinfo{'users'}=scalar(@userlst);
  if ($sysinfo{'users'} < 0) {
    $sysinfo{'users'}=0;
  }
  @userlst=();
}

sub whosonline {
  writeline($config{'themecolor'}."\nWho's Online".$config{'promptcolor'}.":");

  @whosonline=();
  @wholst=<$config{'home'}$config{'nodes'}/*>;
  foreach $whoon(@wholst) {
    open(in,"<$whoon");
    $person=<in>;
    close(in);
    push(@whosonline,$person);
  }
  @whosonline=sort {$a <=> $b} @whosonline;
  writeline($config{'systemcolor'},1);
format whosonline =
@<<<< @<<<<<< @<<<<<<<<<<<<<<<  .....  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$whonode,$whoproto,$whouser,$whowhere
.
  $whonode="Node"; $whouser="User-ID"; $whoproto="Via";$whowhere="Location";
  $~="whosonline";
  write;
  $~="stdout";
  writeline($config{'datacolor'});
  foreach $node(@whosonline) {
    chomp ($node);
    ($ip,$whonode,$pid,$time,$whouser,$whoproto,$whowhere)=split(/\|/,$node);
    $whonode=sprintf("%03D",$whonode);
    $~="whosonline";
    write;
    $~="stdout";
  }
  writeline($RST."\n");
  unless ($_[0] =~/nopause/) {
    pause();
  }
}


sub iamat {
  unless (-d "$config{'home'}$config{'nodes'}") {
    mkdir "$config{'home'}$config{'nodes'}";
  }
  unless ($info{'hidden'} eq "Y") {
   $who=$_[0];
  } else {
   $who="*** HIDDEN ***";
  }
   $location=$_[1];
   $whofile=$config{'home'}.$config{'nodes'}."/".$info{'node'};
   lockfile("$whofile");
   open (who,">$whofile");
    print who $sysinfo{'ip'}."|".$info{'node'}."|".$$."|".time."|".$who."|".$info{'proto'}."|".$location;
   close (who);
   unlockfile("$whofile");
}


sub errorout {
  cbreak(off);
  logger ("ERROR".$config{'promptcolor'}.": ".$_[0]." ".$info{'handle'}." on node ".$info{'node'}." Exiting..");
  writeline("\n".$config{'errorcolor'}."ERROR".$config{'promptcolor'}.": ".$config{'datacolor'}.$_[0]."\nExiting..",1);
  bye();
}

sub bye {
  if ($info{'handle'}) {}
  iamat($info{'handle'},"Logging off!");
  cbreak(off);
  writeline($theme{'goodbyemsg'}.$RST,1);
  if ($config{'nodupes'} eq 1) {
    if (-e "$config{'home'}$config{'data'}/iplist") {
      lockfile("$config{'home'}$config{'data'}/iplist");
      open (in,"<$config{'home'}$config{'data'}/iplist");
      lockfile("$config{'home'}$config{'data'}/iplist_");
      open (out,">$config{'home'}$config{'data'}/iplist_");
       while (<in>) {
        chomp $_;
        if ($_ =~/$info{'connect'}/i) {
          next;
        } else {
           print out $_."\n";
        }
      }
      close(out);
      unlockfile("$config{'home'}$config{'data'}/iplist_");
      close(in);
      unlockfile("$config{'home'}$config{'data'}/iplist");
      unlink ("$config{'home'}$config{'data'}/iplist");
      rename ("$config{'home'}$config{'data'}/iplist_","$config{'home'}$config{'data'}/iplist");
    }
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}") {
    unlink("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
  }

  if ($info{'handle'}) {
    logger("NOTICE".$config{'promptcolor'}.": ".$info{'handle'}." Logged off!");
  }
  @list=`find $config{'home'} -name $info{'node'} -print`;
  foreach $item(@list) {
    chomp $item;
    system ("rm -rf $item 2>/dev/null");
  }

  if ( -e "$config{'doors'}/nodes/$info{'node'}") {
    system ("rm -rf $config{'doors'}/nodes/$info{'node'} 2>/dev/null");
  }

  unlink ("$config{'home'}$config{'nodes'}/$info{'node'}");
  kill getppid;
  exit(0);
}

sub colorize {
  if ($info{'ansi'} eq "1") {
    $CLR="\e[2J\e[0H";
    $RST="\e[0m";
    $BLK="\e[0;30m"; #BLACK
    $RED="\e[0;31m"; #RED
    $GRN="\e[0;32m"; #GREEN
    $YLW="\e[0;33m"; #YELLOW
    $BLU="\e[0;34m"; #BLUE
    $MAG="\e[0;35m"; #MAGENTA
    $CYN="\e[0;36m"; #WHITE
    $WHT="\e[0;37m"; #CYAN
    $BBK="\e[1;30m"; #GREY
    $BRD="\e[1;31m"; #BRIGHT RED
    $BGN="\e[1;32m"; #BRIGHT GREEN
    $BYL="\e[1;33m"; #BRIGHT YELLOW
    $BBL="\e[1;34m"; #BRIGHT BLUE
    $BMG="\e[1;35m"; #BRIGHT MAGENTA
    $BCN="\e[1;36m"; #BRIGHT CYAN
    $BWH="\e[1;37m"; #BRIGHT WHITE
  } else {
    $CLR="";
    $RST="";
    $BLK="";
    $RED="";
    $GRN="";
    $YLW="";
    $BLU="";
    $MAG="";
    $WHT="";
    $CYN="";
    $BBK="";
    $BRD="";
    $BGN="";
    $BYL="";
    $BBL="";
    $BMG="";
    $BCN="";
    $BWH="";
    print "";
  }
}

sub applytheme {
  $thmfile=$config{'home'}.$config{'themes'}."/".$_[0];
  if (-e $thmfile) {
    lockfile("$thmfile");
    open (atheme,"<$thmfile");
     @themein=<atheme>;
    close (atheme);
    unlockfile("$thmfile");
  } else {
    errorout ("Could not load theme file [".$thmfile."] , exiting..".$RST);
  }
  chomp ($ctime=`date +\%H:\%M`);
  chomp ($cdate=`date +\%Y-\%h-\%d`);
  $menu=lc($menuname);
  foreach (@themein) {
    ($key,$value) = split(/\=/);
    chomp $value;
    unless ($value eq "") {
      $$key = $value;
      $$key =~s/\@SYSTEMCLR/$config{'systemcolor'}/g;
      $$key =~s/\@USERCLR/$config{'usercolor'}/g;
      $$key =~s/\@INPUTCLR/$config{'inputcolor'}/g;
      $$key =~s/\@ERRORCLR/$config{'errorcolor'}/g;
      $$key =~s/\@THEMECLR/$config{'themecolor'}/g;
      $$key =~s/\@PROMPTCLR/$config{'promptcolor'}/g;
      $$key =~s/\@DATACLR/$config{'datacolor'}/g;
      $$key =~s/\@LINECLR/$config{'linecolor'}/g;
      $$key =~s/\@USRNM/$info{'username'}/g;
      $$key =~s/\@SYSNM/$config{'systemname'}/g;
      $$key =~s/\@MENU/$menu/g;
      $$key =~s/\@NODE/$info{'node'}/g;
      $$key =~s/\@CONNECT/$info{'connect'}/g;
      $$key =~s/\@USER/$info{'handle'}/g;
      $$key =~s/\@EMAIL/$info{'email'}/g;
      $$key =~s/\@TIME/$ctime/g;
      $$key =~s/\@DATE/$cdate/g;
      $$key =~s/\@TOTALCALLS/$config{'totcalls'}/g;
      $$key =~s/\@DEFAULT/$info{'defchan'}/g;
      $$key =~s/\@PROTO/$info{'proto'}/g;
      $$key =~s/\@BLK/$BLK/g;
      $$key =~s/\@RED/$RED/g;
      $$key =~s/\@GRN/$GRN/g;
      $$key =~s/\@YLW/$YLW/g;
      $$key =~s/\@BLU/$BLU/g;
      $$key =~s/\@MAG/$MAG/g;
      $$key =~s/\@WHT/$WHT/g;
      $$key =~s/\@CYN/$CYN/g;
      $$key =~s/\@BBK/$BBK/g;
      $$key =~s/\@BRD/$BRD/g;
      $$key =~s/\@BGN/$BGN/g;
      $$key =~s/\@BYL/$BYL/g;
      $$key =~s/\@BBL/$BBL/g;
      $$key =~s/\@BMG/$BMG/g;
      $$key =~s/\@BCN/$BCN/g;
      $$key =~s/\@BWH/$BWH/g;
      $$key =~s/\\n/\n/g; $$key =~s/\\t/\t/g; $$key =~ s/(\$\w+)/$1/eeg;
      $theme{$key}=$$key;
      $$key="";
    }
  }
}

sub lockfile {
  $tolock=$_[0];
  $lockwait=5;
  while (-e "$tolock.lock") {
    --$lockwait;
    if ($lockwait eq 0) {
      last;
    }
    sleep 1;
  }
  if ($lockwait le 0) {
    logger("ERROR: $info{'handle'} forced unlock on $tolock");
    unlink("$tolock.lock");
  }
  open(out,">$tolock.lock");
    print out $info{'handle'};
  close(out);
  chmod 0777,"$tolock.lock";
}

sub unlockfile {
   $tolock=$_[0];
   unlink("$tolock.lock");
}

sub readconfig {
  $rfile=$config{'home'}.$config{'data'}."/".$_[0];
  lockfile("$rfile");
  open (config,"<$rfile");
  while (<config>) {
    $line=$_;
    chomp $line;
    unless ($line =~/^#/) {
      if ($line =~/#/i) {
        ($newline,$junk)=split(/#/,$line);
        while ($newline =~/\s$/) {
          chop $newline;
        }
        $line=$newline;
      }
      ($key,$value)=split(/=/,$line);
      $config{$key}=$value;
    }
  }
  close (config);
  unlockfile("$rfile");
}

sub cbreak {
  if ($_[0] eq "on") {
    if ($BSD_STYLE) {
      system "stty -echo cbreak <$mytty >$mytty 2>&1";
    } else {
      system "stty -echo raw opost <$mytty >$mytty 2>&1";
    }
  }
  if ($_[0] eq "off") {
    if ($BSD_STYLE) {
      system "stty echo -cbreak <$mytty >$mytty 2>&1";
    } else {
      system "stty echo -raw <$mytty >$mytty 2>&1";
    }
  }
}

sub waitkey {
  $idle=time;
  $idlenotified=0;
  $default=$_[0];
  $key="";
  cbreak(on);
  for (;;) {
    wastart: {
    eval {
      local $SIG{ALRM}=sub{$key="";doevents();goto wastart;};
      alarm 1;
      $key = "";
      $key=getc(STDIN);
      doevents();
      alarm 0;
    };
    };

    if ($key ne "") {
      unless ($key eq "\n") {
        writeline ($config{'inputcolor'}.$key);
      } else {
        $key=$default;
        writeline ($config{'inputcolor'}.$key);
      }
      last;
    } else {
      next;
    }
  }
  return $key;
}

sub writeline {
  $wrline=$_[0];
  $wrline =~s/\@RST/$RST/g;
  $wrline =~s/\@BLK/$BLK/g;
  $wrline =~s/\@RED/$RED/g;
  $wrline =~s/\@GRN/$GRN/g;
  $wrline =~s/\@YLW/$YLW/g;
  $wrline =~s/\@BLU/$BLU/g;
  $wrline =~s/\@MAG/$MAG/g;
  $wrline =~s/\@WHT/$WHT/g;
  $wrline =~s/\@CYN/$CYN/g;
  $wrline =~s/\@BBK/$BBK/g;
  $wrline =~s/\@BRD/$BRD/g;
  $wrline =~s/\@BGN/$BGN/g;
  $wrline =~s/\@BYL/$BYL/g;
  $wrline =~s/\@BBL/$BBL/g;
  $wrline =~s/\@BMG/$BMG/g;
  $wrline =~s/\@BCN/$BCN/g;
  $wrline =~s/\@BWH/$BWH/g;
  print $wrline;
  if ($_[1] eq "1") {
    print "\n";
  }
}

sub getline {
  $idle=time;
  $idlenotified=0;
  cbreak("on");
  $input{'type'}=$_[0];
  $input{'length'}=$_[1];
  $input{'text'}=$_[2];
  $result="";
  if ($_[3]) {
    $result=$input{'text'};
    for (1..$input{'length'}) {
      print "\e[0;47;0m ";   ### Add to theme file!
    }
    print "\e[".$input{'length'}."D";
  }
  writeline ($config{'inputcolor'}.$input{'text'});
  for (;;) {
    start: {
    eval {
      local $SIG{ALRM}=sub{$key="";doevents();goto start;};
      alarm 1;
      $key="";
      $key=getc(STDIN);
      doevents();
      alarm 0;
    };
    };
    if ($key =~/\n/ || $key =~/\r/) {
      chomp $result;
      $retmsg=$result;
      $result="";
      print $RST;
      unless ($retmsg ne "") {
        print $RST;
      }
      cbreak(off);
      if ($input{'type'} =~/chat/) {
        print "\e[80D\e[2K";
      } else {
        writeline("\n");
      }
      return ($retmsg);
    }
    if ($key =~/\c?/ || $key =~/\ch/) {
      unless ($result eq "") {
        @parts=split(//,$result);
        $junk=pop(@parts);
        $result=join('',@parts);
        print "\e[1D \e[1D";
      }
      next;
    }
    if (ord($key) >= "32" && ord($key) <= "126") {
      if ($input{'type'} eq "dob") {
        $input{'length'}=10;
        unless ($key =~/[0-9]/) {
          $key="";
          next;
        }
        if (length($result) eq 1) {
          $key=$key."/";
        }
        if (length($result) eq 2) {
          $key="/".$key;
        }
        if (length($result) eq 4) {
          $key=$key."/";
        }
        if (length($result) eq 5) {
          $key="/".$key;
        }
      }
      if ($input{'type'} eq "phone") {
        $input{'length'}=14;
        unless ($key =~/[0-9]/) {
          $key="";
          next;
        }
        if (length($result) lt 1) {
          $key="(".$key;
        }
        if (length($result) eq 3) {
          $key=$key.")";
        }
        if (length($result) eq 4) {
          $key=")".$key;
        }
        if (length($result) eq 5) {
          $key=" ".$key;
        }
        if (length($result) eq 8) {
          $key=$key."-";
        }
        if (length($result) eq 9) {
          $key="-".$key;
        }
      }
      unless (length($result) eq $input{'length'}) {
        unless ($input{'type'} =~/password/) {
          print $key;
        } elsif ($key ne "") {
          print $config{'passchr'};
        }
        $result=$result.$key;
        if ($input{'type'} =~/chat/) {
          if ($result eq "$config{'help'}") {
            $retmsg=$result;
            $result="";
            writeline("\n");
            return ($retmsg);
          }
        }
      }
    }
  }
}

sub colorline {
  $_[0] =~s/\@SYSTEMCLR/$config{'systemcolor'}/g;
  $_[0] =~s/\@USERCLR/$config{'usercolor'}/g;
  $_[0] =~s/\@INPUTCLR/$config{'inputcolor'}/g;
  $_[0] =~s/\@ERRORCLR/$config{'errorcolor'}/g;
  $_[0] =~s/\@THEMECLR/$config{'themecolor'}/g;
  $_[0] =~s/\@PROMPTCLR/$config{'promptcolor'}/g;
  $_[0] =~s/\@DATACLR/$config{'datacolor'}/g;
  $_[0] =~s/\@LINECLR/$config{'linecolor'}/g;
  $_[0] =~s/\@RST/$RST/g;
  $_[0] =~s/\@BLK/$BLK/g;
  $_[0] =~s/\@RED/$RED/g;
  $_[0] =~s/\@GRN/$GRN/g;
  $_[0] =~s/\@YLW/$YLW/g;
  $_[0] =~s/\@BLU/$BLU/g;
  $_[0] =~s/\@MAG/$MAG/g;
  $_[0] =~s/\@WHT/$WHT/g;
  $_[0] =~s/\@CYN/$CYN/g;
  $_[0] =~s/\@BBK/$BBK/g;
  $_[0] =~s/\@BRD/$BRD/g;
  $_[0] =~s/\@BGN/$BGN/g;
  $_[0] =~s/\@BYL/$BYL/g;
  $_[0] =~s/\@BBL/$BBL/g;
  $_[0] =~s/\@BMG/$BMG/g;
  $_[0] =~s/\@BCN/$BCN/g;
  $_[0] =~s/\@BWH/$BWH/g;
  return $_[0];
}

sub readfile {
  if ($_[2]) {
    $filename=$_[0];
  } else {
      $filename=$config{'home'}.$config{'text'}."/".$_[0];
  }
  $pause=$_[1];
  usersonline();
  lockfile("$filename") || errorout ("Unable to open $filename");
  open (file,"<$filename") || errorout ("Unable to open $filename");
  $linecount=1;
  $menu=lc($menuname);
  chomp ($ctime=`date +\%H:\%M`);
  chomp ($cdate=`date +\%Y-\%h-\%d`);
  while (<file>) {
    s/\@SYSTEMCLR/$config{'systemcolor'}/g;
    s/\@USERCLR/$config{'usercolor'}/g;
    s/\@INPUTCLR/$config{'inputcolor'}/g;
    s/\@ERRORCLR/$config{'errorcolor'}/g;
    s/\@THEMECLR/$config{'themecolor'}/g;
    s/\@PROMPTCLR/$config{'promptcolor'}/g;
    s/\@DATACLR/$config{'datacolor'}/g;
    s/\@LINECLR/$config{'linecolor'}/g;
    s/\@SYSNM/$config{'systemname'}/g;
    s/\@NODE/$info{'node'}/g;
    s/\@CONNECT/$info{'connect'}/g;
    s/\@HOST/$sysinfo{'host'}/g;
    s/\@IP/$sysinfo{'ip'}/g;
    s/\@USERS/$sysinfo{'users'}/g;
    s/\@TIME/$ctime/g;	s/\@DATE/$cdate/g;
    s/\@DEFAULT/$info{'defchan'}/g;
    s/\@PROTO/$info{'proto'}/g;
    s/\@USER/$info{'handle'}/g;
    s/\@RNAME/$info{'rname'}/g;
    s/\@DOB/$info{'dob'}/g;
    s/\@PHONE/$info{'phonenumber'}/g;
    s/\@LOCAL/$info{'location'}/g;
    s/\@CREDITS/$info{'credits'}/g;
    s/\@TLEFT/$info{'tlimit'}/g;
    s/\@ID/$info{'id'}/g;
    s/\@SEX/$info{'sex'}/g;
    s/\@EMAIL/$info{'email'}/g;
    s/\@DND/$info{'dnd'}/g;
    s/\@BANNED/$info{'banned'}/g;
    s/\@CLR/$CLR/g;
    s/\@RST/$RST/g;
    s/\@BLK/$BLK/g;
    s/\@RED/$RED/g;
    s/\@GRN/$GRN/g;
    s/\@YLW/$YLW/g;
    s/\@BLU/$BLU/g;
    s/\@MAG/$MAG/g;
    s/\@WHT/$WHT/g;
    s/\@CYN/$CYN/g;
    s/\@BBK/$BBK/g;
    s/\@BRD/$BRD/g;
    s/\@BGN/$BGN/g;
    s/\@BYL/$BYL/g;
    s/\@BBL/$BBL/g;
    s/\@BMG/$BMG/g;
    s/\@BCN/$BCN/g;
    s/\@BWH/$BWH/g;
    s/~AT/\@/g;

    if ($info{'ansi'} eq 1) {
      $ansi="Y";
    } else {
      $ansi="N";
    }
    s/\@ANSI/$ansi/g;
    s/\\n/\n/g;
    s/\\t/\t/g;

    unless ($inteleconf eq 1) {
      print $_;
    } else {
      chomp $_;
      unless ($_ eq "") {
        print "\e[80D\e[2K".$_."\n";
        $gotapage="1";
      }
    }

    if ($gotapage eq "1") {
      writeline($RST.$config{'inputcolor'}.$config{'promptchr'}." ".$result);
    }

    unless ($pause eq "1") {
      ++$linecount;
      if ($linecount == $config{'rows'}) {
        unless ($wait eq "C") {
          $wait=pause();
        }
        if ($wait eq "Q") {
          last;
        }
        if ($wait eq "N") {
          $linecount=1;
        }
      }
    }
  }
  close (file);
  unlockfile("$filename") || errorout ("Unable to open $filename");
}

sub pause {
  writeline ($theme{'pause'}." ".$RST);
  $noevents=1;
  $key=waitkey();
  $noevents="";
  $key=uc($key);
  print "\e[2K\e[80D";
  unless ($key =~/C/ || $key =~/N/ || $key =~/Q/) {
    $key="N";
  }
  return $key;
}

sub hi {
  $ppid=getppid;
  if ( $ARGV[1] =~ /sftp/i  || $ARGV[1] =~ /scp/i || $ARGV[1] =~ /exec/i ) {
    writeline("Attempt reported.",1);
    logger("ERROR: Connection attempt via SCP or SFTP from (@ARGV).");
    exit 0;
  }
  unless ($info{'connect'} ne "") {
    if ($ARGV[1] ne "") {
      $info{'connect'}=$ARGV[1];
      $info{'proto'}="TELNET";
    } else {
      if($ENV{'SSH_CLIENT'}) {
        @sshprts=split(/\ /,$ENV{'SSH_CLIENT'});
        $info{'connect'}=shift(@sshprts);
        $info{'proto'}="SSH";
      } else {
        $info{'connect'}=$mtty;
        $info{'proto'}="LOCAL";
      }
    }
  }

  $cli=join(' ',@ARGV);
  chomp ($cli);

  unless ($info{'connect'} =~/\w\.\w/i || $info{'connect'} =~/\w{4,32}/i) {
     writeline("Dont know who you are, can not continue.");
     logger ("ERROR: Can't find IP address for connection ($cli), disconnecting.");
     bye()
  }

  if ($config{'nodupes'} eq 1) {
    unless (-e "$config{'home'}$config{'data'}/iplist") {
      open (out,">$config{'home'}$config{'data'}/iplist");
       print out "UNKNOWNUSER\n";
      close(out);
    }
    if (-e "$config{'home'}$config{'data'}/iplist") {
      lockfile("$config{'home'}$config{'data'}/iplist");
      open (in,"<$config{'home'}$config{'data'}/iplist");
      lockfile("$config{'home'}$config{'data'}/iplist_");
      open (out,">$config{'home'}$config{'data'}/iplist_");
       while (<in>) {
        chomp $_;
        if ($_ =~/$info{'connect'}/i) {
          writeline ($config{'systemcolor'}."\nIP ".$config{'usercolor'}.$info{'connect'}.$config{'systemcolor'}." is already logged on ..",1);
          ($kpid,$kip)=split(/:/,$_);
          logger("WARN: Duplicate IP ".$info{'connect'}." connected. Killing PID ".$kpid);
	        kill 15,$kpid;
          bye();
        }
      }


      print out getppid."".$config{'promptcolor'}.":".$info{'connect'}."\n";
      close(out);
      unlockfile("$config{'home'}$config{'data'}/iplist_");
      close(in);
      unlockfile("$config{'home'}$config{'data'}/iplist");
      unlink ("$config{'home'}$config{'data'}/iplist");
      rename ("$config{'home'}$config{'data'}/iplist_","$config{'home'}$config{'data'}/iplist");
    }
  }

  cbreak(on);
  eval {
    if ( $config{'clearlogin'} = "1" ) {
       print "\e[2J\e[0H";
    }
    if ($config{'headers'} eq 1) {
      @OPENING=split(//,"\nConnected to ".$config{'systemname'})
    }
    push (@OPENING,"\nAuto-sensing .");
    for (0..scalar(@OPENING)) {
     select(undef, undef, undef, 0.010);
     print shift(@OPENING);
    }

    local $SIG{ALRM} = sub {$response="\c[6c";next;};
    print "\e[c";
    alarm 1;
    while ($tchr=getc(STDIN)){
      $termmode=$termmode.getc(STDIN);
      if ($termmode =~/\cx/i) {
        $termmode="1c";
        last;
      } elsif ($termmode =~/[0-9]c/i) {
       last;
      }
    }
    alarm 0;
  };
  print ".";
  if ($termmode =~/[0-1]c/gi) {
    $info{'ext'}="asc";
    $info{'ansi'}="0";
  } else {
    $info{'ext'}="ans";
    $info{'ansi'}="1";
  }
  eval {
    alarm 1;
    local $SIG{ALRM} = sub {$tchr="c";next;};
    while ($tchr=$tchr.getc(STDIN)) {
      if ($tchr =~/c$/i) {
        last;
      }
    }
    alarm 0;
  };
  print ".";
  eval {
    alarm 1;
      local $SIG{ALRM} = sub {$tchr="";next;};
      while ($tchr=$tchr.getc(STDIN)) {
        last;
      }
    alarm 0;
  };
  print ".";
  chomp ($info{'tty'}=`tty | sed -e s#/##g -e s#[a-z]##g`);

  ###
  ### Multinode support requires generating the node number without the tty, and
  ### doors support requires the node number to be less than 100 for most.  So..
  ### support a total of 99 nodes (configurable)
  ###

  for (1..$config{'totalnodes'}) {
    $info{'node'}=$_;
    unless (-e "$config{'home'}$config{'nodes'}/$info{'node'}") {
     iamat("CONNECT","Logging on");
     last;
    }
  }

  unless ($info{'tty'} =~/[0-9]/i) {
    @parts=split(//,$info{'tty'});
    $tty=pop(@parts);
    $node=ord($tty);
    $node=$node-96;
    $info{'node'}=$node;
  }

  if (-e "$config{'home'}$config{'messages'}/$info{'node'}.page") {
    unlink("$config{'home'}$config{'messages'}/$info{'node'}.page");
  }

  if (-e "$config{'home'}$config{'data'}/banned_ip") {
    lockfile("$config{'home'}$config{'data'}/banned_ip");
    open (in,"<$config{'home'}$config{'data'}/banned_ip");
      while(<in>) {
        chomp $_;
          if ($info{'connect'} =~/$_/i) {
            writeline ($config{'systemcolor'}."\nHost ".$config{'usercolor'}.$info{'connect'}.$config{'systemcolor'}." has been ".$config{'errorcolor'}."banned".$config{'systemcolor'}.", terminating connection ..",1);
	          logger("WARN: Banned User connected from".$config{'promptcolor'}.": ".$info{'connect'});
	          close(in);
            unlockfile("$config{'home'}$config{'data'}/banned_ip");
            bye();
          }
      }
    close(in);
    unlockfile("$config{'home'}$config{'data'}/banned_ip");
  }

  if (-e "$config{'home'}/$config{'data'}/totalcalls") {
    lockfile("$config{'home'}/$config{'data'}/totalcalls");
    open (tcalls,"<$config{'home'}/$config{'data'}/totalcalls");
    $config{'totcalls'}=<tcalls>;
    chomp ($config{'totcalls'});
    close (tcalls);
    unlockfile("$config{'home'}/$config{'data'}/totalcalls");
  }
  ++$config{'totcalls'};
  lockfile("$config{'home'}/$config{'data'}/totalcalls");
  open (tcalls,">$config{'home'}/$config{'data'}/totalcalls");
   print tcalls $config{'totcalls'};
  close (out);
  unlockfile("$config{'home'}/$config{'data'}/totalcalls");

}

sub logger {
  system ("logger -p $config{'facility'} -t \"$sysinfo{'servername'}\" \"$_[0]\"");
  if ( $config{'slackintegration'} eq "1" ) {
    if ( $config{'slackerrors'} eq "0" && "$_[0]" =~ /^ERR/ ) {
      return;
    }
    if ( $config{'slackwarnings'} eq "0" && "$_[0]" =~ /^WARN/ ) {
      return;
    }
    system ('curl -X POST --data-urlencode "payload={\"channel\": \"'.$config{'slackchannel'}.'\", \"username\": \"'.$config{'slackuser'}.'\", \"text\": \"'.$_[0].'\", \"icon_emoji\": \"'.$config{'slackemoji'}.'\"}" "https://hooks.slack.com/services/'.$config{'slackapipath'}.'" >/dev/null 2>&1');
  }
}

sub bulletins {
  $bullidx=$config{'home'}.$config{'data'}."/bullidx.dat";
  if (-e $bullidx) {
    lockfile("$bullidx");
    open (in,"<$bullidx");
    @bulls=<in>;
    close (in);
  }
  unlockfile("$bullidx");
  if (scalar(@bulls) > "0") {
    writeline($config{'themecolor'}."Found ".$config{'datacolor'}.scalar(@bulls).$config{'themecolor'}." bulletin(s)!",1);
  } else {
    writeline($config{'systemcolor'}."No new bulletins are available today.",1);
    return;
  }
  if ($config{'bulletins'} eq 0) {
    return;
  }
  bullmenu();
}

sub bullmenu {
  bullmenu: {
    $inteleconf=0;
    writeline("\n");
    iamat($info{'handle'},"Bulletins Menu");
    $count=1;

    ###
    ### bulletins.xxx should contain the index
    ### if it doesn't exist, generate a menu
    ###

    $readit=0;
    if (-e "$config{'home'}$config{'text'}/bulletins.$info{'ext'}") {
      readfile("welcome.$info{'ext'}");
      $readit=1;
    }
    if (-e "$config{'home'}$config{'text'}/bulletins.txt" && $readit ne "1") {
      readfile("welcome.txt");
      $readit=1;
    }

    if ($readit ne "1") {
      writeline("$theme{'bulltop'}\n",1);
    }

    $bullidx=$config{'home'}.$config{'data'}."/bullidx.dat";
    lockfile("$bullidx");
    open (in,"<$bullidx");
    @bulls=<in>;
    close (in);
    unlockfile("$bullidx");

    unless($readit eq 1) {
      for (0..scalar(@bulls)) {
        $bulln=$_+1;
        chomp ($bulls[$_]);
        ($bullid,$bulltext)=split(/\|/,$bulls[$_]);
        if ($bulltext ne "") {
          writeline($config{'datacolor'}.$bulln.$config{'usercolor'}." ...".$config{'themecolor'}." ".$bulltext,1);
        }
      }
    }

    writeline($config{'themecolor'}."\nEnter Option, or \"".$config{'datacolor'}."Q".$config{'themecolor'}."\" to quit".$config{'promptcolor'}.": ");
    $result=getline(text,,1);
    unless ($result =~/^[Qq]$/ || $result eq "") {
      iamat($info{'handle'},"Reading a bulletin");
      $result=$result-1;
      if ($result lt 0) {
        $result=0;
      }
      chomp ($bulls[$_]);
      ($bullid,$bulltext)=split(/\|/,$bulls[$result]);
      if (-e "$config{'home'}/$config{'text'}/$bullid") {
        writeline("\n");
        readfile($bullid);
        goto bullmenu;
      }
    }
    writeline("\n");
  }
  $inteleconf=1;
}

return 1;
