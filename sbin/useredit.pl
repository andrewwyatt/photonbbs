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
    print "$config{$key}=$value;\n";
  }
  close(in);
} else {
  die "Please configure your BBS (/etc/default/photonbbs)";
}

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

applytheme($config{'theme'});
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
  writeline ($config{'themecolor'}."User Editor - ".$config{'usercolor'}." [ ".$config{'systemcolor'}.$info{'id'}.$config{'usercolor'}."/".$config{'systemcolor'}.scalar(@users).$config{'usercolor'}." ]",1);
  writeline ("",1);
  writeline ("",1);
  writeline ($config{'datacolor'}."A. ".$config{'usercolor'}."Handle : ".$config{'systemcolor'}.$info{'handle'},1);
  writeline ($config{'datacolor'}."B. ".$config{'usercolor'}."Real Name : ".$config{'systemcolor'}.$info{'rname'},1);
  writeline ($config{'datacolor'}."C. ".$config{'usercolor'}."D.O.B. : ".$config{'systemcolor'}.$info{'dob'},1);
  writeline ($config{'datacolor'}."D. ".$config{'usercolor'}."Email Address : ".$config{'systemcolor'}.$info{'email'},1);
  writeline ($config{'datacolor'}."E. ".$config{'usercolor'}."Location : ".$config{'systemcolor'}.$info{'location'},1);
  writeline ("",1);
  writeline ($config{'datacolor'}."F. ".$config{'usercolor'}."Password : ".$config{'systemcolor'}."********",1);
  writeline ($config{'datacolor'}."G. ".$config{'usercolor'}."Security : ".$config{'systemcolor'}.$info{'security'},1);
  writeline ("",1);
  writeline ($config{'datacolor'}."H. ".$config{'usercolor'}."Ansi : ".$config{'systemcolor'}.$ansi,1);
  writeline ($config{'datacolor'}."I. ".$config{'usercolor'}."Do Not Disturb : ".$config{'systemcolor'}.$dnd,1);
  writeline ($config{'datacolor'}."J. ".$config{'usercolor'}."Hidden : ".$config{'systemcolor'}.$info{'hidden'},1);
  writeline ($config{'datacolor'}."K. ".$config{'usercolor'}."Theme : ".$config{'systemcolor'}.$info{'theme'},1);
  writeline ($config{'datacolor'}."L. ".$config{'usercolor'}."Default channel : ".$config{'systemcolor'}.$info{'defchan'},1);
  writeline ($config{'datacolor'}."M. ".$config{'usercolor'}."Account Banned : ".$config{'systemcolor'}.$info{'banned'},1);
  writeline ("",1);
  writeline ($config{'datacolor'}."[. ".$config{'usercolor'}."Previous User",1);
  writeline ($config{'datacolor'}."]. ".$config{'usercolor'}."Next User",1);
  writeline ($config{'themecolor'}."Enter Option, or \"".$config{'datacolor'}."Q".$config{'themecolor'}."\" to quit: ");

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
    chemail();
    next;
  }

  if ($key =~/^[Ee]/) {
    chlocal();
    next;
  }

  if ($key =~/^[Ff]/) {
    chpassword();
    next;
  }

  if ($key =~/^[Gg]/) {
    chsecurity();
    next;
  }

  if ($key =~/^[Hh]/) {
    chansi();
    next;
  }

  if ($key =~/^[Ii]/) {
    chdnd();
    next;
  }

  if ($key =~/^[Jj]/) {
    #hide
  }

  if ($key =~/^[Kk]/) {
    chtheme();
    next;
  }

  if ($key =~/^[Ll]/) {
    chdefault();
    next;
  }

  if ($key =~/^[Mm]/) {
    chbanned();
    next;
  }

}

sub chtheme {
    opthe: {
    writeline($config{'themecolor'}."Please enter a new theme to use: ");
    $info{'theme'}=getline(text,20,"",1);
    unless (-e $config{'home'}.$config{'themes'}."/".$info{'theme'}) {
      writeline($RED."That theme does not exist, please choose another.",1);
      goto opthe;
    }
  }
  updateuser();
}

sub chdefault {
  writeline($config{'themecolor'}."Please enter a new default channel: ");
  $info{'defchan'}=getline(text,20,"",1);
  $info{'defchan'}=uc($info{'defchan'});
  $info{'defchan'}=~s/\ /_/gi;
  updateuser();
}

sub chhandle {
  opnewid: {
    writeline($config{'themecolor'}."Please enter a new handle: ");
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
    writeline($config{'themecolor'}."Please enter a new security level: ");
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
