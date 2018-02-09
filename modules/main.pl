#!/usr/bin/perl

sub pageall {
  $msg=$_[0];
  @sendtonodes=`ls $config{'home'}$config{'nodes'}`;
  foreach $snode(@sendtonodes) {
    chomp $snode;
    unless ($snode eq $info{'node'}) {
      lockfile("$config{'home'}$config{'messages'}/$snode.page");
      open(out,">>$config{'home'}$config{'messages'}/$snode.page");
      print out "\n\@LTB[\@YLW".$info{'handle'}."\@LTB] \@WHT".$msg."\n";
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/$snode.page");
    }
  }
}

sub sendpage {
   $page=$_[0];
   chomp ($page);
   @parts=split(/\s/,$page);
   $pguser=shift(@parts);
   $found=0;
   @usersonline=();
   @wholst=<$config{'home'}$config{'nodes'}/*>;
   foreach $whoon(@wholst) {
     lockfile("$whoon");
     open(in,"<$whoon");
     $person=<in>;
     close(in);
     unlockfile("$whoon");
     push(@usersonline,$person);
   }

   foreach $rec(@usersonline) {
     chomp ($rec);
     ($pnode,$user,$pproto,$where)=split(/\|/,$rec);
     $pguser=uc($pguser);
     $user=uc($user);
     if ($user eq "$pguser") {
        $found=1;
        $pmsg=join(' ',@parts);
     }
     $parts[0]=uc($parts[0]);
     if ($user eq "$pguser $parts[0]") {
        $pguser=$pguser.$parts[0];
        $junk=shift(@parts);
        $found=1;
        $pmsg=join(' ',@parts);
     }
     $parts[1]=uc($parts[1]);
     if ($user eq "$pguser $parts[0] $parts[1]") {
       $pguser=$pguser.$parts[0].$parts[1];
       $junk=shift(@parts);
       $junk=shift(@parts);
       $found=1;
       $pmsg=join(' ',@parts);
     }

     if ($found eq "1") {
       ($pnode,$user,$where)=split(/\|/,$rec);
       writeline($LGN."Paging ".$user."..",1);
       lockfile("$config{'home'}$config{'messages'}/$pnode.page");
       open (out,">>$config{'home'}$config{'messages'}/$pnode.page");
       print out "\n\@LTB[\@YLW".$info{'handle'}."\@LTB]\@WHT is paging you from the @PRED".$_[1]."\@WHT ..\n";
       print out "\@WHT".$pmsg."\n\@RST";
       close (out);
       unlockfile("$config{'home'}$config{'messages'}/$pnode.page");
       last;
     }
  }
  if ($found ne "1") {
    writeline($LTB.$pguser.$PPL." is not online",1);
  }
}

sub getpages {
  if (-e "$config{'home'}/$config{'messages'}/$info{'node'}.page") {
    readfile("$config{'home'}/$config{'messages'}/$info{'node'}.page",1,1);
    $gotapage=0;
    unlink("$config{'home'}/$config{'messages'}/$info{'node'}.page");
  }
}

sub telechannel {
    $channel=$_[0];
    $channel=~s/\s/_/g;
    $channel=~s/\W//g;
    $op=0;
    $canjoin=0;

    unless (-d "$config{'home'}$config{'messages'}/teleconf/TELEPUB_") {
      mkdir ("$config{'home'}$config{'messages'}/teleconf/TELEPUB_");
    }

    ### Watch this code for a while..
    @chanlist=<$config{'home'}$config{'messages'}/teleconf/*>;
    foreach $rchan(@chanlist) {
      @rlchan=split(/\//,$rchan);
      $lchan=pop(@rlchan);
      chomp $lchan;
      if ($lchan =~/$channel/i) {
        $channel=$lchan;
        last;
      }
    }
    @rlchan=();
    @chanlist=();

    unless (-d "$config{'home'}$config{'messages'}/teleconf/$channel") {
      mkdir ("$config{'home'}$config{'messages'}/teleconf/$channel");
      mkdir ("$config{'home'}$config{'messages'}/teleconf/$channel/users");
      mkdir ("$config{'home'}$config{'messages'}/teleconf/$channel/messages");
      writeline($WHT."\nCreated channel ".$YLW.$channel.$WHT." ..",1);
      lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
      open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/owner");
       print out $info{'handle'};
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
      writeline($WHT."Assigned ".$YLW.$info{'handle'}.$WHT." as channel owner ..",1);
    }

    unless ($channel =~/$config{'defchannel'}/) {

      if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/owner") {
        lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
        open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/owner");
          @chanown=<in>;
        close (in);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
        foreach $item(@chanown) {
          chomp $item;
          if ($item =~/$info{'handle'}/) {
            $canjoin = 1;
            $op = 1;
            last;
          }
        }
      }

      if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ops") {
        lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
        open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          @chanops=<in>;
        close (in);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
        foreach $item(@chanops) {
          chomp $item;
          if ($item =~/$info{'handle'}/) {
            $canjoin = 1;
            $op = 1;
            last;
          }
        }
      }

      unless ($ops eq 1) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/banned") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/banned");
           @chanban=<in>;
          close (in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
          foreach $item(@chanban) {
            chomp $item;
            if ($item =~/$info{'handle'}/) {
              writeline ($WHT."You are not allowed to join ".$YLW.$channel.$WHT." ..",1);
              writeline($WHT."Entering channel ".$YLW.$config{'defchannel'},1);
              unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
              telechannel($config{'defchannel'});
            }
          }
        }
      }

      if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ssh") {
        if ($info{'proto'} =~/SSH/) {
          $canjoin=1;
        } else {
          $canjoin=0;
        }
      } else {
        $canjoin=1;
      }
      unless ($op eq 1) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/allow") {
          $canjoin=0;
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/allow");
           @chanallow=<in>;
          close (in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          foreach $citem(@chanallow) {
            chomp $citem;
            if ($info{'handle'} =~/$citem/) {
              $canjoin=1;
              last;
            }
          }
        } else {
          $canjoin=1;
        }

        unless ($canjoin eq 1) {
          writeline ($WHT."You are not allowed to enter channel ".$YLW.$channel.$WHT." ..",1);
          $canjoin=0;
          writeline($WHT."Entering channel ".$YLW.$config{'defchannel'},1);
          telechannel($config{'defchannel'});
        }
      }
    }

    lockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
    open (out,">$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
    unless ($info{'hidden'} eq "Y") {
     print out $info{'node'}."|".$info{'handle'}."|".$channel."\n";
    } else {
     print out $info{'node'}."|*** HIDDEN ***|".$channel."\n";
    }
    close (out);
    unlockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");

    lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
    open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
     print out $info{'handle'};
    close (out);
    unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");

    $channelusers="";
    @teleusers=`ls $config{'home'}$config{'messages'}/teleconf/$channel/users/* 2>/dev/null`;
    $telelen=scalar(@teleusers);
    @teleusers=sort @teleusers;
    $tlucount=scalar(@teleusers);
    if (scalar(@teleusers) gt "1") {
      foreach $teleuser(@teleusers) {
        chomp ($teleuser);
        lockfile("$teleuser");
        open (in,"<$teleuser");
        $line=(<in>);
        close (in);
        unlockfile("$teleuser");
        chomp ($line);

        unless ($line eq $info{'handle'}) {
          if (scalar(@teleusers) gt 2) {
            $channelusers=$channelusers.", ".$line;
          } else {
            if (scalar(@teleusers) eq 2) {
              $channelusers=$channelusers.$line;
            }
          }
        }
      }
    if ($channelusers =~/\,/i) {
      @channeluserlist=split(/\,\s/,$channelusers);
      $lastchanneluser=pop(@channeluserlist);
      $channeluserlist=join(', ',@channeluserlist);
      $channelusers=$channeluserlist.", and ".$lastchanneluser;
      @channeluserlist=();
    }
    } else {
      $channelusers="There is nobody else here with you.";
    }



     if (scalar(@teleusers) gt 2) {
      $channelusers=~s/^,\s//;
      $channelusers=$channelusers." are here with you.";
    } else {
      if (scalar(@teleusers) eq 2) {
        $channelusers=$channelusers." is here with you.";
      }
    }
    $leaving="1";
    unless ($rescan eq "1") {
      logger("NOTICE: ".$info{'handle'}." joined ".$channel);
      iamat($info{'handle'},"Chat");
      telesend("just entered the room!");
    }
    $leaving="0";
}

sub teleconf {
  $chatline="";
  $dndmode=$info{'dnd'};
  $info{'dnd'}="0";

  unless (-d "$config{'home'}$config{'messages'}/teleconf") {
    mkdir ("$config{'home'}$config{'messages'}/teleconf");
  }
  unless ($info{'defchan'} ne "") {
    writeline ($WHT."Joining the ".$PPL.$config{'defchannel'}.$WHT." channel ..");
    telechannel($config{'defchannel'});
  } else {
    writeline ($WHT."Joining the ".$PPL.$info{'defchan'}.$WHT." channel ..");
    telechannel($info{'defchan'});
  }
  if ( $config{'systemname'} ) {
    writeline ($YLW."\n\n".$config{'systemname'},1);
  } else {
    writeline ("\n\n");
  }
 channel: {
  if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/allow") {
    $private=" (".$PPL."PRIVATE".$LGN.")";
  } else {
    $private="";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ssh") {
    $private=$private." (".$PPL."ENC".$LGN.")";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/message") {
    $inteleconf=0;
    readfile("$config{'home'}$config{'messages'}/teleconf/$channel/message",1,1);
    $inteleconf=1;
    writeline($RST,1);
  }

  writeline ($LGN."You are in the ".$PPL.$channel.$LGN." channel".$private.".\n".$RST.$channelusers."\n");

  if ($channel =~/$config{'defchannel'}/) {
    writeline($YLW."Press \"".$LTB.$config{'help'}.$YLW."\" for a list of commands.\n");
  }

  telemain: {
    loaduser($info{'id'});
    if ($info{'banned'} eq "Y") {
      $leaving="1";
      telesend("was banned from the system!");
      writeline($RED."You have been banned from this system, disconnecting.");
      $leaving="0";
      $atmenu="0";
      $inteleconf="0";
      $info{'dnd'}=$dndmode;
      unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
      goto leave;
    }

    writeline($theme{'prompt'});
    $atmenu="1";
    $inteleconf="1";
    doevents();
    $chatline=getline(chat,$config{'buffer'});
    if ($chatline eq "") {
      $rescan="1";
      telechannel($channel);
      $rescan="0";
      writeline("",1);
      goto channel;
    }

    if ($chatline =~/^\/[Bb][Uu][Ll][Ll][Ee][Tt][Ii][Nn][Ss]$/ || $chatline =~/^\@$/) {
      $chatline="";
      bulletins();
      goto telemain;
    }

    if ($chatline =~/^\/[Oo][Nn][Ee][Ll][Ii][Nn][Ee][Rr][Ss]$/ || $chatline =~/^\%$/) {
      $chatline="";
      oneliners();
      goto telemain;
    }

    if ($chatline =~/^\/[Hh][Ii][Dd][Ee]$/ || $chatline =~/^\/[Hh]$/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not hide the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }
      if (teleowner()) {
        unless (-e "$config{'home'}$config{'messages'}/teleconf/$channel/hidden") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." hidden ..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
           print out "1";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
        } else {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is no longer hidden ..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
          goto telemain;
        }
        goto telemain;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Ii][Nn][Vv]$/ || $chatline=~/^\!$/) {
      chhide();
      goto telemain;
    }

    if ($chatline =~/^\/[Uu][Ss][Ee][Rr][Ss]$/ || $chatline =~/^#$/ || $chatline =~/^\/[Ww][Hh][Oo]$/) {
      if (length($chatline) le "6") {
        whosonline(nopause);
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Ss][Ee][Tt]\ / || $chatline =~/^\/[Uu]\ /) {
      ($junk,$setcommand)=split(/\s/,$chatline);
      if ($setcommand =~/DEFAULT/i) {
        if ($info{'defchan'} =~/$channel/) {
           writeline($WHT."Reset  ".$PPL.$config{'defchannel'}.$WHT." as your favorite.",1);
           $info{'defchan'}=$config{'defchannel'};
        } else {
           writeline($WHT."Saved ".$PPL.$channel.$WHT." as your favorite.",1);
           $info{'defchan'}=$channel;
           updateuser();
       }
        goto telemain;
      }
      if ($setcommand =~/NAME/i) {
        chrealname();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/PASSWORD/i) {
        chpassword();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/LOCATION/i) {
        chlocal();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/EMAIL/i) {
        chemail();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/PHONE/i) {
        chphone();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/DOB/i) {
        chdob();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/SEX/i) {
        chsex();
        writeline($RST,1);
        goto telemain;
      }
      if ($setcommand =~/ANSI/i) {
        chansi();
        writeline($RST,1);
        goto telemain;
      }
      writeline($WHT."Unknown ".$YLW."SET".$WHT." command",1);
      goto telemain;
    }

    if ($chatline =~/^\/[Bb][Aa][Nn]\ / || $chatline =~/^\/[Bb]\ /) {
      ($junk,$banuser)=split(/\s/,$chatline);

      $banuser=lc($banuser);
      $banuser=ucfirst($banuser);

      if ($banuser eq "") {
        writeline ($WHT."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not (un)ban users in the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
       $unallned=0;
       if ($banuser eq $info{'handle'}) {
         writeline ($WHT."You can not ban yourself from a channel ..", 1);
         goto telemain;
       }
       if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/banned") {
         lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
         open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/banned");
         lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned_");
         open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/banned_");
         while (<in>) {
           chomp $_;
           if ($_ eq $banuser) {
             writeline ($WHT."User ".$YLW.$banuser.$WHT." is no longer banned from ".$YLW.$channel.$WHT." ..",1);
             $unallned=1;
             next;
           } else {
              print out $_."\n";
           }
         }
         close(out);
         close(in);
         unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
         rename ("$config{'home'}$config{'messages'}/teleconf/$channel/banned_","$config{'home'}$config{'messages'}/teleconf/$channel/banned");
         unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
         unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned_");
         unless ($unallned eq 0) {
           goto telemain;
         }
       }
       writeline ($WHT."User ".$YLW.$banuser.$WHT." now banned from ".$YLW.$channel.$WHT." ..",1);
       lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
       open (out,">>$config{'home'}$config{'messages'}/teleconf/$channel/banned");
        print out $banuser."\n";
       close (out);
       unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
       goto telemain;
     } else {
       goto telemain;
     }


     writeline ($WHT."User ".$YLW.$banuser.$WHT." no longer banned from entering ".$YLW.$channel.$WHT." ..",1);
     lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
     open (out,">>$config{'home'}$config{'messages'}/teleconf/$channel/banned");
      print out $banuser."\n";
     close (out);
     unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
     goto telemain;
    }

    if ($chatline =~/^\/[Ss][Tt][Aa][Tt][Uu][Ss]$/i || $chatline =~/^\/\$$/ || $chatline =~/^\$$/) {
      if ($op eq 1) {
        writeline($WHT."\nSystem report for channel: ".$PPL.$channel.$WHT."\n",1);
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/owner") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$channel/owner");
            $rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
          chomp $rep;
          writeline($LTB."Channel Owner: ".$LGN.$rep,1)
        }
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/banned") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$channel/banned");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/banned");
          writeline($LTB."Banned users: ");
          if (scalar(@rep) gt 0) {
            foreach $brep(@rep) {
              chomp $brep;
              unless ($brep =~/$info{'handle'}/) {
                writeline($LGN.$brep." ");
              }
            }
            writeline($RST,1);
          } else {
            writeline($LGN."None",1);
          }
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/allow") {
          writeline($LTB."Room is ".$LGN."PRIVATE".$RST,1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$channel/allow");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          writeline($LTB."Allowed users: ");
          if (scalar(@rep) gt 1) {
            foreach $brep(@rep) {
              chomp $brep;
              unless ($brep =~/$info{'handle'}/) {
                writeline($LGN.$brep." ");
              }
            }
            writeline($RST,1);
          } else {
            writeline($LGN."None",1);
          }
        } else {
          writeline($LTB."Room is ".$LGN."PUBLIC",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ops") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$channel/ops");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          writeline($LTB."Channel Operators: ");
          if (scalar(@rep) gt 0) {
            foreach $brep(@rep) {
              chomp $brep;
              unless ($brep =~/$info{'handle'}/) {
                writeline($LGN.$brep." ");
              }
            }
            writeline($RST,1);
          } else {
            writeline($LGN."None",1);
          }
        } else {
          writeline($LTB."There are no channel ops other than its owner",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/hidden") {
          writeline($LTB."This room is ".$LGN."HIDDEN FROM".$LTB." channel scans",1);
        } else {
          writeline($LTB."This room is ".$LGN."SHOWN IN".$LTB." channel scans",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ssh") {
          writeline($LTB."This room requires ".$LGN."SSH".$LTB." connections",1);
        } else {
          writeline($LTB."This room is open to ".$LGN."UNENCRYPTED".$LTB." connections",1);
        }

        goto telemain;
      } else {
        writeline ($WHT."You are not a chanop",1);
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Tt][Oo][Pp][Ii][Cc]\ / || $chatline =~/^\/[Tt]\ /) {
      @parts=split(/\s/,$chatline);
      $junk=shift(@parts);
      $chanmsg=join(' ',@parts);
      chomp($chanmsg);

      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not change the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
        if ($chanmsg eq "") {
          unlink("$config{'home'}$config{'messages'}/teleconf/$channel/message");
          writeline ($WHT."Removed Channel message ..",1);
        } else {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/message");
          open(out,">$config{'home'}$config{'messages'}/teleconf/$channel/message");
          print out "\@LGNTopic: \@YLW".$chanmsg;
          close(out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/message");
          writeline($WHT."Set Channel message ..",1);
        }
        writeline("",1);
        goto channel;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Pp][Rr][Ii][Vv][Aa][Tt][Ee]$/ || $chatline =~/^\/[Vv]$/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not change the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/allow") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."PUBLIC".$WHT."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
        } else {
  	 writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."PRIVATE".$WHT."..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          print out $info{'handle'}."\n";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
        }
        writeline("",1);
        goto channel;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Ss][Ss][Ll]$/ || $chatline =~/^\/[Ee]$/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not change the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ssh") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."UNENCRYPTED OK".$WHT."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/ssh");
        } else {
         unless ($info{'proto'} =~/SSH/) {
           writeline ($RED."Warning: Can not change channel properties; you are connected via ".$LTB.$info{'proto'}.$RED."..",1);
           writeline("",1);
           goto channel;
         }
         writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."ENCRYPT ONLY".$WHT."..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ssh");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/ssh");
          print out $info{'handle'}."\n";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ssh");
        }
        writeline("",1);
        goto channel;
      } else {
        goto telemain;
      }
    }
    if ($chatline =~/^\/[Cc][Hh][Aa][Nn][Nn][Ee][Ll][Ss]$/ || $chatline =~/^\/[Cc]$/) {
      chanscan();
      goto telemain;
    }

    if ($chatline =~/^\/[Oo][Pp]\ / || $chatline =~/^\/[Oo]\ /) {
      ($junk,$opuser)=split(/\s/,$chatline);

      $opuser=lc($opuser);
      $opuser=ucfirst($opuser);

      if ($opuser =~/$info{'handle'}/) {
        writeline ($WHT."You can not un-op yourself ".$info{'handle'}." ..",1);
        $opuser = "";
      }

      if ($opuser eq "") {
        writeline ($WHT."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not change ChanOP users in the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
        $unallned=0;
        if ($opuser eq $info{'handle'}) {
          writeline ($WHT."You can not remove ChanOP from yourself ..", 1);
          goto telemain;
        }
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ops") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops_");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/ops_");
          while (<in>) {
            chomp $_;
            if ($_ eq $opuser) {
              writeline ($WHT."User ".$YLW.$opuser.$WHT." is no longer ChanOP in channel ".$YLW.$channel.$WHT." ..",1);
              $unallned=1;
              next;
            } else {
               print out $_."\n";
            }
          }
          close(out);
          close(in);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          rename ("$config{'home'}$config{'messages'}/teleconf/$channel/ops_","$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops_");
          unless ($unallned eq 0) {
            goto telemain;
          }
        }
        writeline ($WHT."User ".$YLW.$opuser.$WHT." ChanOP of channel ".$YLW.$channel.$WHT." ..",1);
        lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
        open (out,">>$config{'home'}$config{'messages'}/teleconf/$channel/ops");
         print out $opuser."\n";
        close (out);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
        goto telemain;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Aa][Ll][Ll][Oo][Ww]\ / || $chatline =~/^\/[Ll]\ /) {
      ($junk,$alluser)=split(/\s/,$chatline);

      $alluser=lc($alluser);
      $alluser=ucfirst($alluser);

      if ($alluser =~/$info{'handle'}/) {
        writeline ($WHT."You can not unallow yourself ".$info{'handle'}." ..",1);
        $alluser = "";
      }

      if ($alluser eq "") {
        writeline ($WHT."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not (un)allow users in the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if (teleowner()) {
        $unallned=0;
        if ($alluser eq $info{'handle'}) {
          writeline ($WHT."You can not unallow yourself from a channel ..", 1);
          goto telemain;
        }
        if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/allow") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow_");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/allow_");
          while (<in>) {
            chomp $_;
            if ($_ eq $alluser) {
              writeline ($WHT."User ".$YLW.$alluser.$WHT." is no longer allowed to enter ".$YLW.$channel.$WHT." ..",1);
              $unallned=1;
              next;
            } else {
               print out $_."\n";
            }
          }
          close(out);
          close(in);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          rename ("$config{'home'}$config{'messages'}/teleconf/$channel/allow_","$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow_");
          unless ($unallned eq 0) {
            goto telemain;
          }
        }
        writeline ($WHT."User ".$YLW.$alluser.$WHT." now allowed to enter ".$YLW.$channel.$WHT." ..",1);
        lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
        open (out,">>$config{'home'}$config{'messages'}/teleconf/$channel/allow");
         print out $alluser."\n";
        close (out);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
        goto telemain;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Ss][Cc][Aa][Nn]$/ || $chatline =~/^\/[Ss]$/) {
      if (length($chatline) le "6") {
        telescan();
        goto telemain;
      }
    }
    if ($chatline =~/^\/[Ii][Nn][Ff][Oo]$/ || $chatline =~/^\/[Ii]$/) {
       $inteleconf="0";
       readfile("account.txt");
       $inteleconf="1";
      goto telemain;
    }

    if ($chatline eq "$config{'help'}") {
       $inteleconf="0";
       readfile("telehelp.txt");
       $inteleconf="1";
      goto telemain;
    }

    if ($chatline =~/^\/[Jj]/ || $chatline =~/^\/[Jj][Oo][Ii][Nn]/) {
      $leaving="1";
      telesend("just left the channel!");
      $leaving="0";
      unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
      ($junk,$channel)=split(/\s/,$chatline);
      if ($channel eq "") {
        $channel=$config{'defchannel'};
      }
      writeline($WHT."Entering channel ".$YLW.$channel.$WHT." ...\n",1);
      telechannel($channel);
      goto channel;
    }
    if ($chatline =~/^\/[Ww]\ / || $chatline =~/^\/[Ww][Hh][Ii][Ss][Pp][Ee][Rr]\ /) {
      ($jnk,$data)=split(/\s/,$chatline,2);
      telewhisper($data);
      goto telemain;
    }
    if ($chatline =~/^\/[Aa]\ / || $chatline =~/^\/[Aa][Cc][Tt][Ii][Oo][Nn]\ / || $chatline =~/^\/[Mm][Ee]\ /) {
      @parts=split(//,$chatline);
      $mchoice="";
      for (@parts) {
        $test=shift(@parts);
        if ($test eq " ") {
          last;
        }
        $mchoice=$mchoice.$test;
      }
      $chatline=join('',@parts);
      $chatline =~s/\@LGN/$LGN/g;     $chatline =~s/\@BLK/$BLK/g;
      $chatline =~s/\@RED/$RED/g;     $chatline =~s/\@GRN/$GRN/g;
      $chatline =~s/\@BRN/$BRN/g;     $chatline =~s/\@BLU/$BLU/g;
      $chatline =~s/\@PPL/$PPL/g;     $chatline =~s/\@LGR/$LGN/g;
      $chatline =~s/\@GRY/$GRY/g;     $chatline =~s/\@PNK/$PNK/g;
      $chatline =~s/\@YLW/$YLW/g;     $chatline =~s/\@ALB/$ALB/g;
      $chatline =~s/\@VLT/$VLT/g;     $chatline =~s/\@WHT/$WHT/g;
      $chatline =~s/\@LTB/$LTB/g;     $chatline =~s/\@RST/$RST/g;
      telesend($chatline);
      goto telemain;
    }
    if ($chatline =~/^[Xx]$/ || $chatline =~/^\/[Qq][Uu][Ii][Tt]$/ || $chatline =~/^[Ee][Xx][Ii][Tt]$/) {
      writeline($theme{'exita'}.$theme{'exitb'});
      $choice=waitkey("N");
      if ($choice =~/[Yy]/) {
        writeline ($WHT."\nLogging off..",1);
        $leaving="1";
        telesend("just left the channel!");
        $leaving="0";
        $atmenu="0";
        $inteleconf="0";
        $info{'dnd'}=$dndmode;
        unlink ("$config{'home'}$config{'messages'}/teleconf/$channel/users/$info{'node'}");
        goto leave;
      } else {
        writeline ("",1);
        $chatline="";
        goto telemain;
      }
    }

    $runthis=0;

    if (-e "$config{'home'}$config{'data'}/external.mnu") {
      lockfile("$config{'home'}$config{'data'}/external.mnu");
      open(in,"<$config{'home'}$config{'data'}/external.mnu");
       @mnuitems=<in>;
      close(in);
      unlockfile("$config{'home'}$config{'data'}/external.mnu");
      foreach $mnuitem(@mnuitems) {
        if ($mnuitem =~/^#/) {
          next;
        }
        ($mitem,$mname,$mdesc,$mexec,$mseclevel,$mhidden,$mspecial,$mnumusers)=split(/\|/,$mnuitem);
        if ($chatline =~/^$mitem/i && $info{'security'} ge $mseclevel) {
          $runthis=1;
          last;
        }
      }
      if ($runthis eq 1) {
        $leaving="1";
        telesend($mdesc);
        $leaving="0";
        writeline($WHT.$info{'handle'}." ".$mdesc,1);
        $prevchan=$channel;
        $rescan="1";
        unlink ("$config{'home'}$config{'messages'}/teleconf/$prevchan/users/$info{'node'}");
        telechannel($mname);
        if ( $mhidden eq 1) {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
           print out "1";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/hidden");
        }
        $rescan="0";
        if ($mhidden eq 0) {
          iamat($info{'handle'},$mname);
        }

        logger("NOTICE: ".$info{'handle'}." executed ".$mexec);

        if ($mspecial =~/internal/) {
          &$mexec();
        }

        if ($mspecial =~/external/) {
          $dndmode=$info{'dnd'};
          $info{'dnd'}="1";
          if ($numusers gt 0) {
            $numuserslock=$config{'home'}.$config{'data'}."/".$mexec;
            if (-e $numuserslock) {
              writeline($theme{'inuse'},1);
              pause();
              return;
            } else {
              lockfile($numuserslock);
              open (out,">$numuserslock");
               print out $info{'handle'};
              close(out);
              unlockfile($numuserslock);
            }
          }
          $run=$config{'home'}.$config{'sbin'}."/".$mexec." ".$config{'home'}." ".$info{'node'}." \"".$info{'handle'}."\"";
          system ($run);
          if (-e $numuserslock) {
           lockfile($numuserslock);
           unlink($numuserslock);
           unlockfile($numuserslock);
           $numuserslock="";
          }
          doevents();
       }
      writeline($RST."\n",1);
      #$rescan="1";
      unlink ("$config{'home'}$config{'messages'}/teleconf/$mname/users/$info{'node'}");
      telechannel($prevchan);
      #$rescan="0";
      loaduser($info{'id'});
      goto channel;
;
      }
    }
    ### End door Stuff
    #
    telesend();
  }
  goto telemain;
  leave: {
    last;
    $plcholder="1";
  }
 }
}

sub teleowner {
  if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/owner") {
    lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
    open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/owner");
    chomp ($chanowner=<in>);
    close (in);
    unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
  } else {
    unless ($channel eq $config{'defchannel'}) {
      writeline ($WHT."You are the new owner of the ".$YLW.$channel.$WHT." channel ..",1);
      lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
      open (out,">$config{'home'}$config{'messages'}/teleconf/$channel/owner");
        print out $info{'handle'};
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/owner");
      lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
      open (out,">>$config{'home'}$config{'messages'}/teleconf/$channel/allow");
      print out $info{'handle'}."\n";
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/allow");
      $chanowner=$info{'handle'};
      if ($alluser eq $info{'handle'}) {
        return 1;
      }
    }
  }

  unless ($chanowner eq $info{'handle'}) {
    if (-e "$config{'home'}$config{'messages'}/teleconf/$channel/ops") {
      lockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
      open (in,"<$config{'home'}$config{'messages'}/teleconf/$channel/ops");
      chomp (@chanops=<in>);
      close (in);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$channel/ops");
      foreach $cops(@chanops) {
        chomp $cops;
        if ($cops =~/$info{'handle'}/) {
          return 1;
        }
      }
    }

    writeline ($WHT."You do not own the ".$YLW.$channel.$WHT." channel ..",1);
    unless ($info{'security'} ge $config{'chanop'}) {
      return 0;
    } else {
      writeline ($WHT."Channel OP override ..",1);
    }
  }
  return 1;
}

sub telesend {
  $sendmessage=$_[0];
  @telesendto=`ls $config{'home'}$config{'messages'}/teleconf/$channel/users 2>/dev/null`;
  if (scalar(@telesendto) eq 1) {
    unless ($leaving eq 1) {
      writeline ($LGN."There is no one here with you!",1);
    }
  } else {
    foreach $channode(@telesendto) {
      chomp ($channode);
      if ($leaving eq "1") {
        if ($channode eq $info{'node'}) {
          next;
        }
      }
      $sendmessage =~s/\@LGN/$LGN/g;     $sendmessage =~s/\@BLK/$BLK/g;
      $sendmessage =~s/\@RED/$RED/g;     $sendmessage =~s/\@GRN/$GRN/g;
      $sendmessage =~s/\@BRN/$BRN/g;     $sendmessage =~s/\@BLU/$BLU/g;
      $sendmessage =~s/\@PPL/$PPL/g;     $sendmessage =~s/\@LGR/$LGN/g;
      $sendmessage =~s/\@GRY/$GRY/g;     $sendmessage =~s/\@PNK/$PNK/g;
      $sendmessage =~s/\@YLW/$YLW/g;     $sendmessage =~s/\@ALB/$ALB/g;
      $sendmessage =~s/\@VLT/$VLT/g;     $sendmessage =~s/\@WHT/$WHT/g;
      $sendmessage =~s/\@LTB/$LTB/g;     $sendmessage =~s/\@RST/$RST/g;

      $chatline =~s/\@LGN/$LGN/g;     $chatline =~s/\@BLK/$BLK/g;
      $chatline =~s/\@RED/$RED/g;     $chatline =~s/\@GRN/$GRN/g;
      $chatline =~s/\@BRN/$BRN/g;     $chatline =~s/\@BLU/$BLU/g;
      $chatline =~s/\@PPL/$PPL/g;     $chatline =~s/\@LGR/$LGN/g;
      $chatline =~s/\@GRY/$GRY/g;     $chatline =~s/\@PNK/$PNK/g;
      $chatline =~s/\@YLW/$YLW/g;     $chatline =~s/\@ALB/$ALB/g;
      $chatline =~s/\@VLT/$VLT/g;     $chatline =~s/\@WHT/$WHT/g;
      $chatline =~s/\@LTB/$LTB/g;     $chatline =~s/\@RST/$RST/g;

      lockfile("$config{'home'}$config{'messages'}/$channode.page");
      open(out,">>$config{'home'}$config{'messages'}/$channode.page");
       unless (defined($sendmessage)) {
         print out "\@YLW".$info{'handle'}."\@LTB".": "."\@WHT".$chatline."\@WHT"."\n";
       } else {
         print out "\@WHT".$info{'handle'}." ".$sendmessage."\@WHT"."\n";
       }
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/$channode.page");
    }
  }
}

sub telewhisper {
   $page=$_[0];
   chomp ($page);
   @parts=split(/\s/,$page);
   $pguser=shift(@parts);
   $found=0;
   @usersonline=();
   @wholst=<$config{'home'}$config{'nodes'}/*>;
   foreach $whoon(@wholst) {
     lockfile("$whoon");
     open(in,"<$whoon");
     $person=<in>;
     close(in);
     unlockfile("$whoon");
     push(@usersonline,$person);
   }

   foreach $rec(@usersonline) {
     chomp ($rec);
     ($pnode,$user,$pproto,$where)=split(/\|/,$rec);
     $pguser=uc($pguser);
     $user=uc($user);
     if ($user eq "$pguser") {
        $found=1;
        $pmsg=join(' ',@parts);
     }
     $parts[0]=uc($parts[0]);
     if ($user eq "$pguser $parts[0]") {
        $pguser=$pguser.$parts[0];
        $junk=shift(@parts);
        $found=1;
        $pmsg=join(' ',@parts);
     }
     $parts[1]=uc($parts[1]);
     if ($user eq "$pguser $parts[0] $parts[1]") {
       $pguser=$pguser.$parts[0].$parts[1];
       $junk=shift(@parts);
       $junk=shift(@parts);
       $found=1;
       $pmsg=join(' ',@parts);
     }
     if ($found eq "1") {

      $pmsg =~s/\@LGN/$LGN/g;     $pmsg =~s/\@BLK/$BLK/g;
      $pmsg =~s/\@RED/$RED/g;     $pmsg =~s/\@GRN/$GRN/g;
      $pmsg =~s/\@BRN/$BRN/g;     $pmsg =~s/\@BLU/$BLU/g;
      $pmsg =~s/\@PPL/$PPL/g;     $pmsg =~s/\@LGR/$LGN/g;
      $pmsg =~s/\@GRY/$GRY/g;     $pmsg =~s/\@PNK/$PNK/g;
      $pmsg =~s/\@YLW/$YLW/g;     $pmsg =~s/\@ALB/$ALB/g;
      $pmsg =~s/\@VLT/$VLT/g;     $pmsg =~s/\@WHT/$WHT/g;
      $pmsg =~s/\@LTB/$LTB/g;     $pmsg =~s/\@RST/$RST/g;

       writeline($YLW."whispered: ".$pmsg,1);
       ($pnode,$user,$where)=split(/\|/,$rec);
       lockfile("$config{'home'}$config{'messages'}/$pnode.page");
       open (out,">>$config{'home'}$config{'messages'}/$pnode.page");
        print out "\@YLW".$info{'handle'}."\@YLW whispers \@LTB: \@WHT".$pmsg."\n";
       close (out);
       unlockfile("$config{'home'}$config{'messages'}/$pnode.page");
       last;
    }
  }
  if ($found ne "1") {
    writeline($LTB.$pguser.$PPL." is not online",1);
  }
}

sub chanscan {
  #iamat($info{'handle'},"Channel List");
  @whosonline=();
  @wholst=<$config{'home'}$config{'messages'}/teleconf/*>;
  writeline("",1);

format chanscan =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<   .....   @<<<<<<<< @<<<<<<< @<<<<< @<<<<<<<
$scannedchan,$chanenc,$chanstat,$chanusers,$exstat
.

  $scannedchan="Channel .....";$chanenc="Protocol";$chanstat="Status";$chanusers="Users";$exstat="";
  writeline($YLW);
  $~="chanscan";
  write;
  $~="stdout";
  writeline($LTB);

  foreach $whoon(@wholst) {
   $chanenc="";
   $chanstat="";
   $exstat="";
   chomp ($whoon);
   if ($whoon =~/TELEPUB_/i) {
     next;
   }
   @thischan=split(/\//,$whoon);
   $scannedchan=pop(@thischan);
   if (-e "$whoon/hidden") {
     unless ($info{'security'} ge $config{'chanop'}) {
       next;
     }
     $exstat="(HIDDEN)";
   }
   if (-e "$whoon/ssh") {
     $chanenc="SSH";
   } else {
     $chanenc="ANY";
   }
   if (-e "$whoon/allow") {
     $chanstat="PRIVATE";
   } else {
     $chanstat="PUBLIC";
   }
   @scanchanusr=<$whoon/users/*>;
   $chanusers=scalar(@scanchanusr);

  writeline($LTB);
  $~="chanscan";
  write;
  $~="stdout";
  }
  writeline($RST,1);

}

sub telescan {
  @whosonline=();
  @wholst=<$config{'home'}$config{'messages'}/teleconf/TELEPUB_/*>;
  foreach $whoon(@wholst) {
    lockfile("$whoon");
    open(in,"<$whoon");
    $person=<in>;
    close(in);
    unlockfile("$whoon");
    push(@whosonline,$person);
  }

  @whosonline=sort {$a <=> $b} @whosonline;
  ### Add a header/footer later
  writeline("\n");

format telescan =
@<<< @<<<<<<<<<<<<<<<   .....   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$whonode,$whouser,$whowhere
.

  $whonode="Node"; $whouser="User-ID"; $whowhere="Channel";
  writeline($YLW);
  $~="telescan";
  write;
  $~="stdout";
  writeline($LTB);
  foreach $node(@whosonline) {
    chomp ($node);
    ($whonode,$whouser,$whowhere)=split(/\|/,$node);
    if (length($whonode) lt 2) {
      $whonode="0".$whonode;
    }
    if (length($whonode)  lt 3) {
      $whonode="0".$whonode;
    }
    $~="telescan";
    if (-e "$config{'home'}$config{'messages'}/teleconf/$whowhere/hidden") {
      $whowhere="*******"
    }
    write;
    $~="stdout";
  }
  writeline($RST."\n");
}


return 1;
