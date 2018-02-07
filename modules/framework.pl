#!/usr/bin/perl
#
#  Photon BBS Framework
#  (C) 2002-2013 Andrew Wyatt

sub doevents {
  ++$idle;
  if ($idle >= $config{'idledisconnect'}/2) {
    if ($idlenotified eq 0) {
      $idletimeleft=$config{'idledisconnect'}-$idle;
      writeline($VLT."\nWarning: Your session will be disconnected in ".$idletimeleft." seconds due to inactivity.");
      $idlenotified=1;
    }
  }
  if ($idle eq $config{'idledisconnect'}) {
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
  writeline($LGN."\nWho's Online:");

  @whosonline=();
  @wholst=<$config{'home'}$config{'nodes'}/*>;
  foreach $whoon(@wholst) {
    open(in,"<$whoon");
    $person=<in>;
    close(in);
    push(@whosonline,$person);
  }
  @whosonline=sort {$a <=> $b} @whosonline;
  writeline("\n");

format whosonline =
@<<<< @<<<<<< @<<<<<<<<<<<<   .....   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$whonode,$whoproto,$whouser,$whowhere
.
  $whonode="Node"; $whouser="User-ID"; $whoproto="Via";$whowhere="Location";
  writeline($YLW);
  $~="whosonline";
  write;
  $~="stdout";
  writeline($LTB);
  foreach $node(@whosonline) {
    chomp ($node);
    ($whonode,$whouser,$whoproto,$whowhere)=split(/\|/,$node);
    if (length($whonode) lt 2) {
      $whonode="0".$whonode;
    } 
    if (length($whonode)  lt 3) {
      $whonode="0".$whonode;
    }
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
  unless ($info{'hidden'} eq "Y") {
   $who=$_[0];
  } else {
   $who="*** HIDDEN ***";
  }
   $location=$_[1];
   $whofile=$config{'home'}.$config{'nodes'}."/".$info{'node'};
   lockfile("$whofile");
   open (who,">$whofile");
    print who $info{'node'}."|".$who."|".$info{'proto'}."|".$location."\n";
   close (who);
   unlockfile("$whofile");
}


sub errorout {
  cbreak(off);
  logger ("ERROR: ".$_[0]." ".$info{'handle'}." on node ".$info{'node'}." Exiting..");
  writeline("\n".$RED."ERROR: ".$LTB.$_[0]."\nExiting..",1);
  bye();
}

sub bye {
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
          #logger("Unlinking IP ".$config{'connect'}." from list");
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

  logger($info{'handle'}." Logged off!");
  @list=`find $config{'home'} -name $info{'node'} -print`;
  foreach $item(@list) {
    chomp $item;
    system ("rm -rf $item 2>/dev/null");
  }
  unlink ("$config{'home'}$config{'nodes'}/$info{'node'}");
  kill getppid;
  exit(0);
}

sub colorize {
  if ($info{'ansi'} eq "1") {
    $CLR="\e[2J\e[0H"; $RST="\e[0m"; $BLK="\e[0;30m"; $RED="\e[0;31m"; $GRN="\e[0;32m"; $BRN="\e[0;33m"; $BLU="\e[0;34m";
    $PPL="\e[0;35m"; $LGR="\e[0;37m"; $GRY="\e[1;30m"; $PNK="\e[1;31m"; $LGN="\e[1;32m"; $YLW="\e[1;33m";
    $ALB="\e[1;34m"; $VLT="\e[1;35m"; $LTB="\e[1;36m"; $WHT="\e[1;37m"; $PBLK="\e[0;30m"; $PRED="\e[0;31m";
    $PGRN="\e[0;32m"; $PBRN="\e[0;33m"; $PBLU="\e[0;34m"; $PPPL="\e[0;35m"; $PLGR="\e[0;37m"; $PGRY="\e[1;30m";
    $PPNK="\e[1;31m"; $PLGN="\e[1;32m"; $PYLW="\e[1;33m"; $PALB="\e[1;34m"; $PVLT="\e[1;35m";
    $PBLU="\e[1;36m"; $PWHT="\e[1;37m";
  } else {
    $CLR=""; $RST=""; $BLK=""; $RED=""; $GRN=""; $BRN=""; $BLU="";
    $PPL=""; $LGR=""; $GRY=""; $PNK=""; $LGN=""; $YLW="";
    $ALB=""; $VLT=""; $LTB=""; $WHT=""; $PBLK=""; $PRED="";
    $PGRN=""; $PBRN=""; $PBLU=""; $PPPL=""; $PLGR=""; $PGRY="";
    $PPNK=""; $PLGN=""; $PYLW=""; $PALB=""; $PVLT="";
    $PBLU=""; $PWHT="";
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
  $menu=uc($menuname);
  foreach (@themein) {
    ($key,$value) = split(/\=/);
    chomp $value;
    unless ($value eq "") {
      $$key = $value;
      $$key =~s/\@LGN/$LGN/g; $$key =~s/\@BLK/$BLK/g; $$key =~s/\@RED/$RED/g; $$key =~s/\@GRN/$GRN/g;
      $$key =~s/\@BRN/$BRN/g; $$key =~s/\@BLU/$BLU/g; $$key =~s/\@PPL/$PPL/g; $$key =~s/\@LGR/$LGR/g;
      $$key =~s/\@GRY/$GRY/g; $$key =~s/\@PNK/$PNK/g; $$key =~s/\@YLW/$YLW/g; $$key =~s/\@ALB/$ALB/g;
      $$key =~s/\@VLT/$VLT/g; $$key =~s/\@WHT/$WHT/g; $$key =~s/\@LTB/$LTB/g;
      $$key =~s/\@USRNM/$info{'username'}/g; $$key =~s/\@SVRNM/$sysinfo{'servername'}/g;
      $$key =~s/\@SYSNM/$config{'systemname'}/g; $$key =~s/\@MENU/$menu/g;
      $$key =~s/\@NODE/$info{'node'}/g; $$key =~s/\@CONNECT/$info{'connect'}/g;
      $$key =~s/\@USER/$info{'handle'}/g; $$key =~s/\@EMAIL/$info{'email'}/g;
      $$key =~s/\@TIME/$ctime/g; $$key =~s/\@DATE/$cdate/g;
      $$key =~s/\@TOTALCALLS/$config{'totcalls'}/g;
      $$key =~s/\@DEFAULT/$info{'defchan'}/g; ### Added at the same time as doors
      $$key =~s/\@PROTO/$info{'proto'}/g;
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
    logger("$info{'handle'} forced unlock on: $tolock");
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
  $idle=0;
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
        print $key;			### Colorize
      } else {
        $key=$default;
        print $key;
      }
      last;
    } else {
      next;
    }
  } 
  return $key;
}

sub writeline {
  print $_[0];
  if ($_[1] eq "1") {
    print "\n";
  }
}

sub getline {
  $idle=0;
  $idlenotified=0;
  cbreak("on");
  $input{'type'}=$_[0];
  $input{'length'}=$_[1];
  $input{'text'}=$_[2];
  $result="";
  if ($_[3]) {
    $result=$input{'text'};
    for (1..$input{'length'}) {
      print "\e[0;47;30m ";   ### Add to theme file!
    }
    print "\e[".$input{'length'}."D";
  }
  print $input{'text'};
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
      if ($input{'type'} =~/phone/ && length($retmsg) ne $input{'length'}) {
        next;
      }
      if ($input{'type'} =~/dob/ && length($retmsg) ne $input{'length'}) {
        next;
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

sub colorline {
  $_[0]=~s/\@LGN/$LGN/g; $_[0]=~s/\@BLK/$BLK/g; $_[0]=~s/\@RED/$RED/g; $_[0]=~s/\@GRN/$GRN/g; $_[0]=~s/\@BRN/$BRN/g;
  $_[0]=~s/\@BLU/$BLU/g; $_[0]=~s/\@PPL/$PPL/g; $_[0]=~s/\@LGR/$LGN/g; $_[0]=~s/\@GRY/$GRY/g; $_[0]=~s/\@PNK/$PNK/g;
  $_[0]=~s/\@YLW/$YLW/g; $_[0]=~s/\@ALB/$ALB/g; $_[0]=~s/\@VLT/$VLT/g; $_[0]=~s/\@WHT/$WHT/g; $_[0]=~s/\@LTB/$LTB/g;
  $_[0]=~s/\@RST/$RST/g; $_[0]=~s/~AT/\@/g;
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
  $menu=uc($menuname);
  chomp ($ctime=`date +\%H:\%M`);
  chomp ($cdate=`date +\%Y-\%h-\%d`);
  while (<file>) {
    s/\@LGN/$LGN/g;	s/\@BLK/$BLK/g;	s/\@RED/$RED/g;	s/\@GRN/$GRN/g;	s/\@BRN/$BRN/g;
    s/\@BLU/$BLU/g;	s/\@PPL/$PPL/g;	s/\@LGR/$LGN/g;	s/\@GRY/$GRY/g;	s/\@PNK/$PNK/g;
    s/\@YLW/$YLW/g;	s/\@ALB/$ALB/g;	s/\@VLT/$VLT/g;	s/\@WHT/$WHT/g;	s/\@LTB/$LTB/g;  
    s/\@RST/$RST/g;	s/\@CLR/$CLR/g;	s/~AT/\@/g;

    s/\@SVRNM/$sysinfo{'servername'}/g;
    s/\@SYSNM/$config{'systemname'}/g;
    s/\@NODE/$info{'node'}/g;
    s/\@CONNECT/$info{'connect'}/g;

    s/\@HOST/$sysinfo{'host'}/g;
    s/\@USERS/$sysinfo{'users'}/g;
    s/\@TIME/$ctime/g;	s/\@DATE/$cdate/g;

    s/\@DEFAULT/$info{'defchan'}/g; ### Added at the same time as doors


    s/\@PROTO/$info{'proto'}/g;
    s/\@USER/$info{'handle'}/g;		### Userinfo
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
      print $WHT.": ".$result;
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
  writeline ($theme{'pause'}.$RST);
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
  logger("Connection established.");
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

  if ($info{'connect'} =~/sftp/i || $info{'connect'} =~/scp/i) {
    writeline("This attempt to copy files has been reported.\nDisconnecting.");
    logger("Connection attempt via SCP or SFTP ($cli).");
    logger("Disconnecting");
    bye();
  }

  unless ($info{'connect'} =~/\w\.\w/i || $info{'connect'} =~/\w{4,32}/i) {
     writeline("Dont know who you are, can not continue.");
     logger ("Can't find IP address for connection ($cli)");
     logger("Disconnecting");
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
          writeline ($WHT."\nIP ".$YLW.$info{'connect'}.$WHT." is already logged on ..",1);
          logger("Duplicate IP: ".$info{'connect'}." connected");
          ($kpid,$kip)=split(/:/,$_);
	  logger("Killed Process: ".$kpid);
	  kill 15,$kpid;
          bye();
        }
      }


      print out getppid.":".$info{'connect'}."\n";
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
    @OPENING=split(//,"\n$sysinfo{'servername'}/$sysinfo{'os'} $sysinfo{'version'} - $sysinfo{'copyright'}\nAuto-sensing .");
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
  $info{'node'}=$info{'tty'}+1;		### Determine node user is connected to from tty
  unless ($info{'tty'} =~/[0-9]/i) {
    @parts=split(//,$info{'tty'});
    $tty=pop(@parts);
    $node=ord($tty);
    $node=$node-96;
    $info{'node'}=$node;
  }

  iamat("CONNECT","Logging on");

  if (-e "$config{'home'}$config{'messages'}/$info{'node'}.page") {
    unlink("$config{'home'}$config{'messages'}/$info{'node'}.page");
  }

  if (-e "$config{'home'}$config{'data'}/banned_ip") {
    lockfile("$config{'home'}$config{'data'}/banned_ip");
    open (in,"<$config{'home'}$config{'data'}/banned_ip");
      while(<in>) {
        chomp $_;
          if ($info{'connect'} =~/$_/i) {
            writeline ($WHT."\nHost ".$YLW.$info{'connect'}.$WHT." has been @REDbanned@WHT, terminating connection ..",1);
	    logger("Banned User connected from: ".$info{'connect'});
	    close(in);
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
    writeline($LGN."Found ".$LTB.scalar(@bulls).$LGN." bulletin(s)!",1); 
  } else {
    writeline($LGN."No new bulletins are available today.",1);
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
          writeline($LTB.$bulln.$YLW." ...".$LGN." ".$bulltext,1);
        }
      }
    }

    writeline($LGN."\nEnter Option, or \"".$LTB."Q".$LGN."\" to quit: ");
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
