#!/usr/bin/perl
#
# User authentication module for PhotonBBS
#

sub authenticate {
  # Reduce the idle disconnect for sessions at the login prompt.
  $defaultidle=$config{'idledisconnect'};
  $config{'idledisconnect'}=90;
  login: {
    unless (defined($tries)) {
      $tries=1;
    } else {
      ++$tries;
    }
    if ($tries > $config{'authretries'}) {
      bye();
    }
    $fuser=$config{'home'}.$config{'data'}."/users.dat";
    unless ( -e "$fuser" ) {
      writeline($theme{'configfirstuser'});
      $config{'sec_user'} = $config{'sec_sysop'};
      $info{'handle'}="NEW";
    }
    unless ( -d "$config{'home'}$config{'data'}/users") {
      mkdir ("$config{'home'}$config{'data'}/users");
    }
    unless ($info{'handle'} ne "") {
      writeline($theme{'login'});
      $info{'handle'}=getline(text,20);
      chomp ($info{'handle'});
      if ($info{'handle'} eq "") {
        $info{'handle'}="Unknown User";
      }
    }
    if ($info{'handle'} =~/[Nn][Ee][Ww]/) {
      newuser();
    }
    if ($firstlogon ne "1") {
      $ucheck=finduser();
      if ($ucheck =~/invalid/) {
        writeline($theme{'nouser'});
        $info{'handle'}="";
        goto login;
      }
      $tries="";
      colorize();
      testpasswd: {
          writeline($theme{'passwordprompt'});
          $result=getline(password,$config{'passlength'});
          @paspts=split(//,$result);
          $pasptst=1;
          foreach $pasprt(@paspts) {
            $pasptst=$pasptst+ord($pasprt);
          }
          $tstpassword=crypt($result,$pasptst);
          until ($tstpassword eq $info{'password'}) {
            writeline($theme{'mismatch'});
            logger("WARN: ".$info{'handle'}." incorrect password on node ".$info{'tty'}." via ".$info{'connect'});
            $tstpassword="";
            unless (defined($tries)) {
              $tries=1;
            } else {
              ++$tries;
            }
            if ($tries eq 4) {
              bye();
            }
            goto testpasswd;
          }
      }
    } else {
      writeline($theme{'fstwelcome'});
    }
    $result="";
    logger("NOTICE: ".$info{'handle'}." logged in on node ".$info{'tty'}." via ".$info{'connect'});
    $config{'idledisconnect'}=$defaultidle;
  }
}

sub getuname {
  $tochk=$_[0];
  $fuser=$config{'home'}.$config{'data'}."/users.dat";
  lockfile("$fuser");
  open (getuname,"<$fuser");
  while (<getuname>) {
    $line=$_;
    chomp ($line);
    ($chkid,$chkname)=split(/\|/,$line);
    if ($chkid eq $tochk) {
      last;
    }
  }
  close (getuname);
  unlockfile("$fuser");
  return "$chkname";
}

sub finduser {
  $tochk=$_[0];
  if ($tochk eq "") {
    $tochk=$info{'handle'};
  }
  $fuser=$config{'home'}.$config{'data'}."/users.dat";
  if ( -e "$fuser" ) {
    lockfile("$fuser");
    open (in,"<$fuser");
    while (<in>) {
      $line=$_;
      chomp ($line);
      ($chkid,$chkname)=split(/\|/,$line);
      if ($chkname eq $tochk) {
        close (in);
        unlockfile("$fuser");
        loaduser($chkid);
        return "valid";
      }
    }
    close (in);
    unlockfile("$fuser");
  }
  return "invalid";
}

sub finduserid {
  $fuser=$config{'home'}.$config{'data'}."/users.dat";
  if ( -e "$fuser" ) {
    lockfile("$fuser");
    open (in,"<$fuser");
    $idcount=0;
    while (<in>) {
      $line=$_;
      chomp ($line);
      ($chkid,$chkname)=split(/\|/,$line);
      if ($chkname eq $info{'handle'}) {
        close (in);
        return $chkid;
      }
      ++$idcount;
    }
    close (in);
    unlockfile("$fuser");
  } else {
    $idcount=0;
  }
  return $idcount;
}

sub loaduser {
  $ruser=$config{'home'}.$config{'data'}."/users/".$_[0].".dat";
  lockfile("$ruser");
  open (in,"<$ruser");
  while (<in>) {
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
      unless ($key =~/node/ || $key =~/connect/){
        $info{$key}=$value;
      } else {
        $info{'lastnode'}=$value;
      }
    }
  }
  close (in);
  unlockfile("$ruser");
  if ($info{'ansi'} eq 0) {
    $info{'ext'}="asc";
  } else {
    $info{'ext'}="ans";
  }
  colorize();
}

sub updateuser {
  unless (defined($info{'id'})) {
    $info{'id'}=finduserid();
    $outto=$config{'home'}.$config{'data'}."/users.dat";
    lockfile("$outto");
    open (out,">>$outto");
      print out $info{'id'}."|".$info{'handle'}."\n";
    close (out);
    unlockfile("$outto");
  }
  $outto=$config{'home'}.$config{'data'}."/users/".$info{'id'}.".dat";
  lockfile("$outto");
  open (out,">$outto");
  foreach $key(keys %info) {
    unless ($key =~/proto/) {
      print out $key."=".$info{$key}."\n";
    }

  }
  logger("NOTICE: Saved ".$info{'handle'}." to record number ".$info{'id'});
  close (out);
  unlockfile("$outto");
}

sub newuser {
  if($config{'public'} eq "0") {
    writeline($theme{'nonewusers'});
    bye();
  }
  logger("NOTICE: New user on Node ".$info{'tty'});
  iamat("New User","Creating an account");
  $readit=0;
  if (-e $info{'home'}."/".$info{'text'}."/welcome.txt") {
    readfile($info{'home'}."/".$info{'text'}."/welcome.txt");
    $readit=1;
  }
  if (-e $info{'home'}."/".$info{'text'}."/welcome".$info{'ext'} && $readit ne 1) {
    readfile($info{'home'}."/".$info{'text'}."/welcome".$info{'ext'});
    $readit=1;
  }
  if ($readit eq 1) {
    writeline($theme{'agreeprompt'});
    $result=waitkey("N");
    unless ($result =~/[Yy]/) {
      $noevents=1;
      writeline($theme{'noagree'});
      $noevents="";
      bye();
    }
  }
  $readit="";
  writeline($theme{'newprompta'});
  writeline($theme{'ansiprompt'});
  $noevents=1;
  $result=waitkey("Y");
  $noevents="";
  if ($result =~/[Yy]/) {
    $info{'ansi'}=1;
  } else {
    $info{'ansi'}=0;
  }

  colorize();
  applytheme($config{'theme'});

  if ($config{'usefullname'} eq "1") {
    fullname: {
      writeline($theme{'fullname'});
      $info{'rname'}=getline(text,50,"",1);
      unless ($info{'rname'} =~/\s/i) {
        writeline($theme{'fullnwrong'});
        goto fullname;
      }
    }
  }
  if ($config{'usephonenum'} eq "1") {
    phonenumber: {
      writeline($theme{'phoneprompt'});
      $info{'phonenumber'}=getline(phone,14,"",1);
    }
  }
  writeline($theme{'locationprompt'});
  $info{'location'}=getline(text,50,"",1);
  email: {
    writeline($theme{'setemaila'});
    $info{'email'}=getline(text,40,"",1);
    unless ($info{'email'} =~/\@/i && $info{'email'} =~/\./i) {
      goto email;
    }
  }
  writeline($theme{'dobprompt'});
  $info{'dob'}=getline(dob,10,"",1);
  until ($info{'sex'} =~/[M|F]/) {
    writeline("\n".$theme{'mfprompt'});
    $info{'sex'}=waitkey("M");
    $info{'sex'}=uc($info{'sex'});
  }
  newid: {
    writeline($theme{'useridprompt'});
    $info{'handle'}=getline(text,16,"",1);
    #$info{'handle'}=ucfirst($info{'handle'});
    chomp ($info{'handle'});
    $handletest=uc($info{'handle'});
    if ($handletest =~/New/gi) {
      $test=" ";
    }
    unless ($handletest =~/\w/i) {
      $test="valid";
    } else {
      $test=finduser($info{'handle'});
    }
    until ($test =~/invalid/i) {
      writeline($theme{'usedidprompt'});
      writeline($theme{'useridprompt'});
      $info{'handle'}=getline(text,16,"",1);
      #$info{'handle'}=ucfirst($info{'handle'});
      $handletest=uc($info{'handle'});
      if ($handletest =~/New/gi) {
        $test=" ";
      }
      unless ($handletest =~/\w/i) {
        $test="valid";
      } else {
        $test=finduser($info{'handle'});
      }
     }
  }
  applytheme($config{'theme'});
  writeline($theme{'idokprompt'});
  $result=waitkey("Y");
  unless ($result =~/[Yy]/) {
    writeline("\n");
    goto newid;
  }
  setpassword: {
    writeline($theme{'setpassword'}.$theme{'setpasswordb'});
    $tmppass=getline(password,$config{'passlength'},"",1);
    @paspts=split(//,$tmppass);
    $pasptst=1;
    foreach $pasprt(@paspts) {
      $pasptst=$pasptst+ord($pasprt);
    }
    $info{'password'}=crypt($tmppass,$pasptst);
    $tmppass="";
    writeline($theme{'setpasswordc'});
    $tmppass=getline(password,$config{'passlength'},"",1);
    $comppass=crypt($tmppass,$pasptst);
    if ($comppass ne $info{'password'}) {
      writeline($theme{'passmatch'});
      goto setpassword;
    }
  }
  if ( $info{'id'} eq 0 ) {
    $info{'security'}=$config{'sec_sysop'};
  } else {
    $info{'security'}=$config{'sec_user'};
  }
  $info{'theme'}=$config{'deftheme'};;
  $info{'dnd'}="0";
  writeline($theme{'remember'});
  $null=waitkey();
  updateuser();
  $firstlogon=1;
}

sub chansi {
  writeline($theme{'ansiprompt'});
  $noevents=1;
  $result=waitkey("Y");
  $noevents="";
  if ($result =~/[Yy]/) {
    $info{'ansi'}=1;
    $info{'ext'}="ans";
  } else {
    $info{'ansi'}=0;
    $info{'ext'}="asc";
  }
  updateuser();
  colorize();
  applytheme($config{'theme'});
}

sub chbanned {
  writeline($theme{'banprompt'});
  $noevents=1;
  $result=waitkey("N");
  $noevents="";
  if ($result =~/[Yy]/) {
    $info{'banned'}="Y";
  } else {
    $info{'banned'}="N";
  }
  updateuser();
  colorize();
  applytheme($config{'theme'});
}

sub chhide {
  if ($info{'proto'} eq "SSH" && $info{'hidden'} ne "Y") {
    writeline($WHT."Sorry, only SSH users can go invisible.",1);
    return;
  }
  if ($info{'hidden'} eq "Y") {
    writeline($WHT."You are no longer invisible.",1);
    $info{'hidden'}="N";
  } else {
    writeline($WHT."You are now invisible.",1);
    $info{'hidden'}="Y";
  }

  iamat($info{'handle'},"Chat");

  if (-e "$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}") {
    lockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
    open (out,">$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
    unless ($info{'hidden'} eq "Y") {
     print out $info{'node'}."|".$info{'handle'}."|".$channel."\n";
    } else {
     print out $info{'node'}."|*** HIDDEN ***|".$channel."\n";
    }
    close (out);
    unlockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
  }
  updateuser();
}

sub chsex {
  $info{'sex'}="";
  until ($info{'sex'} =~/[M|F]/) {
    writeline($theme{'mfprompt'});
    $info{'sex'}=waitkey("M");
    $info{'sex'}=uc($info{'sex'});
  }
  updateuser();
}

sub chphone {
  writeline($theme{'phoneprompt'});
  $info{'phonenumber'}=getline(phone,14,"",1);
  updateuser();
}

sub chdob {
  writeline($theme{'dobprompt'});
  $info{'dob'}=getline(dob,10,"",1);
  updateuser();
}

sub chrealname {
  fullname: {
    writeline($theme{'fullname'});
    $info{'rname'}=getline(text,50,"",1);
    unless ($info{'rname'} =~/\s/i) {
      writeline($theme{'fullnwrong'});
      goto fullname;
    }
  }
  updateuser();
}

sub chpassword {
  passwordch: {
    writeline($theme{'newpassa'});
    $tmppass=getline(password,$config{'passlength'},"",1);
    @paspts=split(//,$tmppass);
    $pasptst=1;
    foreach $pasprt(@paspts) {
      $pasptst=$pasptst+ord($pasprt);
    }
    $info{'password'}=crypt($tmppass,$pasptst);
    $tmppass="";
    writeline($theme{'newpassb'});
    $tmppass=getline(password,$config{'passlength'},"",1);
    $comppass=crypt($tmppass,$pasptst);
    if ($comppass ne $info{'password'}) {
      writeline($theme{'passmatch'});
      goto passwordch;
    }
  }
  updateuser();
}

sub chlocal {
  writeline($theme{'locationprompt'});
  $info{'location'}=getline(text,50,"",1);
  updateuser();
}

sub chdnd {
  unless ($info{'dnd'} eq "1") {
    writeline($LGN."Do not disturb is now ".$YLW."ON".$LGN."\nIt will not be disabled until ".$RED."YOU".$LGN." turn it off",1);
    $info{'dnd'}="1";
  } else {
    writeline($LGN."Do not disturb is now ".$YLW."OFF".$LGN."\nIt will be disabled until ".$RED."YOU".$LGN." turn it on",1);
    $info{'dnd'}="0";
  }
  updateuser();
}

sub chemail {
  writeline($theme{'setemaila'});
  $info{'email'}=getline(text,40,"",1);
  updateuser();
}

return 1;
