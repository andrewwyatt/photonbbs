#!/usr/bin/perl
# 
#  User manager for PhotonBBS
#  (C) 2009 Andrew Wyatt
#  GNU GPL v2
#

$ppid = getppid;
if (-e "/etc/default/photonbbs") {
  open(in,"</etc/default/photonbbs");
  while (<in>) {
    $line=$_;
    chomp $line;
    ($key,$value)=split(/\=/,$line);
    $value=~s/^\"//;
    $value=~s/\".*$//;
    $config{$key}=$value;
  }
  close(in);
} else {
  die "Please configure your BBS (/etc/default/photonbbs)";
}

### System Information
$sysinfo{'servername'}="PhotonBBS";
$sysinfo{'version'}="1.6";
$sysinfo{'copyright'}="(C) 2007-2013 Andrew Wyatt, FEWT Software";
chomp ($sysinfo{'host'}=`hostname`);
####

require ($config{'home'}."/modules/framework.pl");
require ($config{'home'}."/modules/usertools.pl");

$|=1;

$node=@ARGV[2];
if (-e "$config{'doors'}/nodes/$node/fusiondoor") {
  open (in,"<$config{'doors'}/nodes/$node/fusiondoor");
  while (<in>) {
    $instream=$_;
    chomp $instream;
    ($key,$value)=split(/\=/,$instream);
    $fusiondoor{$key}=$value;
  }
  close (in);
  if ($fusiondoor{'security'} <= $config{'sysopsecurity'}) {
    die "You do not have permission to run this tool!";
  }
} else {
  $fusiondoor{'ansi'}=1;
}

chomp($os=`uname`);
if ($os =~/Linux/) {
  $BSD_STYLE=1;
} elsif ($os =~/HP-UX/) {
  $BSD_STYLE=0;
} else {
  $BSD_STYLE=1;
}
chomp ($mytty=`tty`);
open(in,"<$config{'home'}$config{'data'}/users.dat");
  while (<in>) {
    chomp;
    ($idx,$name)=split(/\|/,$_);
    push(@users,$name);
  }
close(in);

applytheme("mbbs");
$sk=0;
for (;;) {
  $usridxcnt=scalar(@users);
  if ($sk < 0) {
    $sk=$usridxcnt;
    --$sk;
  } elsif ($sk >= $usridxcnt) {
    $sk=0;
  }

  loaduser($sk);
  if ($info{'ansi'} eq "0") {
    $ansi="Off";
  } else {
    $ansi="On";
  }

  $save{'ansi'}=$info{'ansi'};
  $save{'ext'}=$info{'ext'};

  $info{'ansi'}=$fusiondoor{'ansi'};
  if ($fusiondoor{'ansi'} eq "1") {
    $info{'ext'}="ans";
  } else {
    $info{'ext'}="asc";
  }
  colorize();

  if ($info{'dnd'} eq "0") {
    $dnd="Off";
  } else {
    $dnd="On";
  }

  print "\e[2J\e[0;0H";
  writeline ($WHT.$sysinfo{'servername'}." ".$sysinfo{'version'},1);
  writeline ($LGN."User Editor - ".$BLU." [ ".$WHT.$info{'id'}.$BLU."/".$WHT.scalar(@users).$BLU." ]",1);
  writeline ("",1);
  writeline ("",1);
  writeline ($LTB."A. ".$YLW."Handle : ".$WHT.$info{'handle'},1);
  writeline ($LTB."B. ".$YLW."Real Name : ".$WHT.$info{'rname'},1);
  writeline ($LTB."C. ".$YLW."D.O.B. : ".$WHT.$info{'dob'},1);
  writeline ($LTB."D. ".$YLW."Sex : ".$WHT.$info{'sex'},1);
  writeline ($LTB."E. ".$YLW."Email Address : ".$WHT.$info{'email'},1);
  writeline ($LTB."F. ".$YLW."Location : ".$WHT.$info{'location'},1);
  writeline ("",1);
  writeline ($LTB."G. ".$YLW."Password : ".$WHT."********",1);
  writeline ($LTB."H. ".$YLW."Security : ".$WHT.$info{'security'},1);
  writeline ("",1);
  writeline ($LTB."I. ".$YLW."Ansi : ".$WHT.$ansi,1);
  writeline ($LTB."J. ".$YLW."Do Not Disturb : ".$WHT.$dnd,1);
  writeline ($LTB."K. ".$YLW."Hidden : ".$WHT.$info{'hidden'},1);
  writeline ($LTB."L. ".$YLW."Theme : ".$WHT.$info{'theme'},1);
  writeline ($LTB."M. ".$YLW."Default channel : ".$WHT.$info{'defchan'},1);
  writeline ($LTB."N. ".$YLW."Account Banned : ".$WHT.$info{'banned'},1);
  writeline ("",1);
  writeline ($LTB."[. ".$YLW."Previous User",1);
  writeline ($LTB."]. ".$YLW."Next User",1);
  writeline ($LGN."Enter Option, or \"".$LTB."Q".$LGN."\" to quit: ");

  $key="";
  cbreak(on);
  $key=waitkey();
  cbreak(off);

  writeline("",1); 

  $info{'ansi'}=$save{'ansi'};
  $info{'ext'}=$save{'ext'};

  if ($key eq "[") {
    --$sk;
    next;
  } elsif ($key eq "]") {
    ++$sk;
    next;
  }
  if ($key =~/^[Qq]/) {
    writeline("$RST");
    exit 0;
  }

  if ($key =~/^[Aa]/) {
    chhandle();
    next;
  }

  if ($key =~/^[Bb]/) {
    chrealname();
    next;
  }

  if ($key =~/^[Cc]/) {
    chdob();
    next;
  }

  if ($key =~/^[Dd]/) {
    chsex();
    next;
  }

  if ($key =~/^[Ee]/) {
    chemail();
    next;
  }

  if ($key =~/^[Ff]/) {
    chlocal();
    next;
  }

  if ($key =~/^[Gg]/) {
    chpassword();
    next;
  }

  if ($key =~/^[Hh]/) {
    chsecurity();
    next;
  }

  if ($key =~/^[Ii]/) {
    chansi();
    next;
  }
 
  if ($key =~/^[Jj]/) {
    chdnd();
    next;
  }

  if ($key =~/^[Kk]/) {
    #hide
  }

  if ($key =~/^[Ll]/) {
    chtheme();
    next;
  }

  if ($key =~/^[Mm]/) {
    chdefault();
    next;
  }

  if ($key =~/^[Nn]/) {
    chbanned();
    next;
  }

}

sub chtheme {
    opthe: {
    writeline($LGN."Please enter a new theme to use: ");
    $info{'theme'}=getline(text,20,"",1);
    unless (-e $config{'home'}.$config{'themes'}."/".$info{'theme'}) {
      writeline($RED."That theme does not exist, please choose another.",1);
      goto opthe;
    }
  }
  updateuser();
}

sub chdefault {
  writeline($LGN."Please enter a new default channel: ");
  $info{'defchan'}=getline(text,20,"",1);
  $info{'defchan'}=uc($info{'defchan'});
  $info{'defchan'}=~s/\ /_/gi;
  updateuser();
}

sub chhandle {
  opnewid: {
    writeline($LGN."Please enter a new handle: ");
    $handle=getline(text,16,"",1);
    $handletest=uc($handle);
    if ($handletest =~/New/gi) {
      $test="valid";
    }
    $test=finduser($handle);
    unless ($test eq "valid") {
       $info{'handle'}=$handle;
       updateuser();
       alterindex();
    } else {
       writeline($RED."Sorry, that name is not available.",1);
       $test="";
       $handle="";
       $handletest="";
       goto opnewid;
    }
  }
}

sub chsecurity {
    opsec: {
    writeline($LGN."Please enter a new security level: ");
    $info{'security'}=getline(text,3,"",1);
    unless ($info{'security'} gt "0") {
      goto opsec;
    }
  }
  updateuser();
}

sub alterindex() {
  $userindex=$config{'home'}.$config{'data'}."/users.dat";
  lockfile("$userindex");
  open (in,"<$userindex");
    @records=<in>;
  close (in);

  open (out,">$userindex");
    foreach $record(@records) {
      chomp $record;
      ($recid,$recname)=split(/\|/,$record);
      if ($recid eq $info{'id'}) {
        $recname=$info{'handle'};
      }
      print out "$recid|$recname\n";
    }
  close(out);
  unlockfile("$userindex");
}
