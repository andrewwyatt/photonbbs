#!/usr/bin/perl

sub pageall {
  $msg=$_[0];
  unless ( -e "$config{'home'}$config{'nodes'}" ) {
    mkdir "$config{'home'}$config{'nodes'}";
  }
  @sendtonodes=<$config{'home'}$config{'nodes'}/*>;
  foreach $snode(@sendtonodes) {
    chomp $snode;
    $snode=~s/^\/.*\///g;
    lockfile("$config{'home'}$config{'messages'}/$snode.page");
    open(out,">>$config{'home'}$config{'messages'}/$snode.page");
    print out "\n\@LTB[\@YLW".$info{'handle'}."\@LTB] \@WHT".$msg."\n";
    close (out);
    unlockfile("$config{'home'}$config{'messages'}/$snode.page");
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
    $op=0;
    $chanexists=0;
    $canjoin=0;

    ###
    ### Users by channel.
    ###

    unless (-d "$config{'home'}$config{'messages'}/teleconf/TELEPUB_") {
      mkdir ("$config{'home'}$config{'messages'}/teleconf/TELEPUB_");
    }

    ###
    ### If the channel list exists, read it in.
    ###
    ### Schema: UUID|owner|Channel Name
    ###

    lockfile("$config{'home'}$config{'messages'}/teleconf/channels");
    if ( -e "$config{'home'}$config{'messages'}/teleconf/channels" ) {
      open (in,"<$config{'home'}$config{'messages'}/teleconf/channels");
      @channels=<in>;
      close(in);
    }

    ###
    ### Does our channel exist? if not create it.
    ###

    foreach $chan(@channels) {
      chomp ($chan);
      ($chanid,$chanown,$channelname) = split(/\|/,$chan);
      if ("$channelname" eq "$channel") {
        $chanexists=1;
        last;
      }
    }

    if ($chanexists eq 0) {
      chomp ($chanid=`uuidgen`);
      open (out,">>$config{'home'}$config{'messages'}/teleconf/channels");
      print out "$chanid|$info{'handle'}|$channel\n";
      close(out);

      $chanown=$info{'handle'};

      unless (-d "$config{'home'}$config{'messages'}/teleconf/$chanid") {
        mkdir ("$config{'home'}$config{'messages'}/teleconf/$chanid");
        mkdir ("$config{'home'}$config{'messages'}/teleconf/$chanid/users");
        mkdir ("$config{'home'}$config{'messages'}/teleconf/$chanid/messages");
      }

      writeline($WHT."\nCreating channel ".$YLW.$channel.$WHT." ..",1);
      writeline($WHT."Assigned ".$YLW.$info{'handle'}.$WHT." as owner ..",1);
    }

    unlockfile("$config{'home'}$config{'messages'}/teleconf/channels");
    @channels=();

    ###
    ### Channel owners can always join any channel
    ###

    if ($chanown eq $info{'handle'}) {
      $canjoin = 1;
      $op = 1;
    }
    if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ops") {
      lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
      open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
        @chanops=<in>;
      close (in);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
      foreach $item(@chanops) {
        chomp $item;
        if ($item eq $info{'handle'}) {
          $canjoin = 1;
          $op = 1;
          last;
        }
      }
    }


  unless ($ops eq 1 || $info{'security'} ge $config{'chanop'}) {
    if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/banned") {
      lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       @chanban=<in>;
      close (in);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      foreach $item(@chanban) {
        chomp $item;
        if ($item eq $info{'handle'}) {
          writeline ($WHT."You are not allowed to join ".$YLW.$channel.$WHT." ..",1);
          writeline($WHT."Entering channel ".$YLW.$config{'defchannel'},1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
          telechannel($config{'defchannel'});
        }
      }
    }
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
    if ($info{'proto'} =~/SSH/) {
      $canjoin=1;
    } else {
      $canjoin=0;
    }
  } else {
    $canjoin=1;
  }
  unless ($op eq 1 || $info{'security'} ge $config{'chanop'}) {
    if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
      $canjoin=0;
      lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
      open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
       @chanallow=<in>;
      close (in);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
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

  lockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
  open (out,">$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");
  unless ($info{'hidden'} eq "Y") {
   print out $info{'node'}."|".$info{'handle'}."|".$chanid."\n";
  } else {
   print out $info{'node'}."|*** HIDDEN ***|".$chanid."\n";
  }
  close (out);
  unlockfile("$config{'home'}$config{'messages'}/teleconf/TELEPUB_/$info{'node'}");

  lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
  open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
   print out $info{'handle'};
  close (out);
  unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");

  $channelusers="";
  @teleusers=<$config{'home'}$config{'messages'}/teleconf/$chanid/users/*>;
  @teleusers=sort @teleusers;
  $usercount=0;

  if (scalar(@teleusers) gt 1) {
    foreach $teleuser(@teleusers) {
      chomp ($teleuser);
      lockfile("$teleuser");
      open (in,"<$teleuser");
      $line=(<in>);
      close (in);
      unlockfile("$teleuser");
      chomp ($line);
      if ($line eq $info{'handle'}) {
        next;
      }
      ++$usercount;
      if ($usercount gt 1) {
        $channelusers=$channelusers.", ".$line;
      } else {
        $channelusers=$channelusers.$line;
      }
    }
    if ($usercount ge 2) {
      @channeluserlist=split(/\,\s/,$channelusers);
      $lastchanneluser=pop(@channeluserlist);
      $channeluserlist=join(', ',@channeluserlist);
      $channelusers=$channeluserlist.", and ".$lastchanneluser;
      @channeluserlist=();
      $channelusers=$channelusers." are here with you.";
    } else {
      $channelusers=$channelusers." is here with you.";
    }
  } else {
    $channelusers="There is nobody else here with you.";
  }

  $leaving="1";
  unless ($rescan eq "1") {
    logger("NOTICE: ".$info{'handle'}." joined ".$chanid);
    iamat($info{'handle'},"Chat");
    telesend("just entered the room!");
  }
  $leaving="0";
}

sub teleconf {
  $chatline="";
  $dndmode=$info{'dnd'};
  $info{'dnd'}="0";

  unless ( -d "$config{'home'}$config{'messages'}" ) {
    mkdir ("$config{'home'}$config{'messages'}");
  }
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
  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
    $private=" (".$PPL."PRIVATE".$LGN.")";
  } else {
    $private="";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
    $private=$private." (".$PPL."ENC".$LGN.")";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/message") {
    $inteleconf=0;
    readfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message",1,1);
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
      unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
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
      if ($info{'handle'} eq $chanown) {
        unless (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." hidden ..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
           print out "1";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
        } else {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is no longer hidden ..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
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

      if ($banuser eq "") {
        writeline ($WHT."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not (un)ban users in the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
       $unallned=0;
       if ($banuser eq $info{'handle'}) {
         writeline ($WHT."You can not ban yourself from a channel ..", 1);
         goto telemain;
       }
       if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/banned") {
         lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
         open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
         lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned_");
         open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/banned_");
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
         unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
         rename ("$config{'home'}$config{'messages'}/teleconf/$chanid/banned_","$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
         unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
         unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned_");
         unless ($unallned eq 0) {
           goto telemain;
         }
       }
       writeline ($WHT."User ".$YLW.$banuser.$WHT." now banned from ".$YLW.$channel.$WHT." ..",1);
       lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
        print out $banuser."\n";
       close (out);
       unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       goto telemain;
     } else {
       goto telemain;
     }


     writeline ($WHT."User ".$YLW.$banuser.$WHT." no longer banned from entering ".$YLW.$channel.$WHT." ..",1);
     lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
     open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      print out $banuser."\n";
     close (out);
     unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
     goto telemain;
    }

    if ($chatline =~/^\/[Ss][Tt][Aa][Tt][Uu][Ss]$/i || $chatline =~/^\/\$$/ || $chatline =~/^\$$/) {
      if ($op eq 1 || $info{'security'} ge $config{'chanop'}) {
        writeline($WHT."\nSystem report for channel: ".$PPL.$channel.$WHT."\n",1);
        writeline($LTB."Channel Owner: ".$LGN.$chanown,1);
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/banned") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
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

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
          writeline($LTB."Room is ".$LGN."PRIVATE".$RST,1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
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

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ops") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          writeline($LTB."Channel Operators: ");
          if (scalar(@rep) gt 0) {
            foreach $brep(@rep) {
              chomp $brep;
              writeline($LGN.$brep." ");
            }
            writeline($RST,1);
          } else {
            writeline($LGN."None",1);
          }
        } else {
          writeline($LTB."There are no channel ops other than its owner",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
          writeline($LTB."This room is ".$LGN."HIDDEN FROM".$LTB." channel scans",1);
        } else {
          writeline($LTB."This room is ".$LGN."SHOWN IN".$LTB." channel scans",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
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

    if ($chatline =~/^\/[Tt][Oo][Pp][Ii][Cc]/ || $chatline =~/^\/[Tt]/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($WHT."Can not change the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown || $info{'security'} ge $config{'chanop'}) {
        lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message");
        system("nano -R $config{'home'}$config{'messages'}/teleconf/$chanid/message");
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message");
        writeline($WHT."Set Channel message ..",1);
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

      if ($info{'handle'} eq $chanown) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."PUBLIC".$WHT."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
        } else {
  	 writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."PRIVATE".$WHT."..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          print out $info{'handle'}."\n";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
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

      if ($info{'handle'} eq $chanown) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
          writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."UNENCRYPTED OK".$WHT."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/ssh");
        } else {
         unless ($info{'proto'} =~/SSH/) {
           writeline ($RED."Warning: Can not change channel properties; you are connected via ".$LTB.$info{'proto'}.$RED."..",1);
           writeline("",1);
           goto channel;
         }
         writeline ($WHT."Channel ".$YLW.$channel.$WHT." is now ".$LTB."ENCRYPT ONLY".$WHT."..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ssh");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/ssh");
          print out $info{'handle'}."\n";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ssh");
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

      if ($opuser =~/$info{'handle'}/ && $info{'security'} ge $config{'chanop'}) {
        writeline ($WHT."You can not un-op yourself ".$info{'handle'}." ..",1);
        $opuser = "";
      }

      if ($opuser eq "") {
        writeline ($WHT."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'} || $info{'security'} lt $config{'sysopsecurity'}) {
        writeline ($WHT."Can not change ChanOP users in the ".$YLW.$config{'defchannel'}.$WHT." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
        $unallned=0;
        if ($opuser eq $info{'handle'}) {
          writeline ($WHT."You can not remove ChanOP from yourself ..", 1);
          goto telemain;
        }
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ops") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops_");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/ops_");
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
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          rename ("$config{'home'}$config{'messages'}/teleconf/$chanid/ops_","$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops_");
          unless ($unallned eq 0) {
            goto telemain;
          }
        }
        writeline ($WHT."User ".$YLW.$opuser.$WHT." ChanOP of channel ".$YLW.$channel.$WHT." ..",1);
        lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
        open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
         print out $opuser."\n";
        close (out);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
        goto telemain;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Aa][Ll][Ll][Oo][Ww]\ / || $chatline =~/^\/[Ll]\ /) {
      ($junk,$alluser)=split(/\s/,$chatline);

      $alluser=lc($alluser);

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

      if ($info{'handle'} eq $chanown) {
        $unallned=0;
        if ($alluser eq $info{'handle'}) {
          writeline ($WHT."You can not unallow yourself from a channel ..", 1);
          goto telemain;
        }
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow_");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/allow_");
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
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          rename ("$config{'home'}$config{'messages'}/teleconf/$chanid/allow_","$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow_");
          unless ($unallned eq 0) {
            goto telemain;
          }
        }
        writeline ($WHT."User ".$YLW.$alluser.$WHT." now allowed to enter ".$YLW.$channel.$WHT." ..",1);
        lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
        open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
         print out $alluser."\n";
        close (out);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
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
      unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
      @parts=split(/\s/,$chatline);
      $junk=shift(@parts);
      $channel=join(" ",@parts);
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

    if ($chatline =~/^\/[Rr]\ / || $chatline =~/^\/[Bb][Rr][Oo][Aa][Dd][Cc][Aa][Ss][Tt]\ /) {
      if ($info{'security'} ge $config{'chanop'}) {
        ($jnk,$data)=split(/\s/,$chatline,2);
        pageall($data);
      }
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
      writeline($theme{'exita'}.$theme{'exitb'}." ");
      $choice=waitkey("N");
      if ($choice =~/[Yy]/) {
        writeline ($WHT."\nLogging off..",1);
        $leaving="1";
        telesend("just left the channel!");
        $leaving="0";
        $atmenu="0";
        $inteleconf="0";
        $info{'dnd'}=$dndmode;
        unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
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
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
           print out "1";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
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
      unlink ("$config{'home'}$config{'messages'}/teleconf/$mname/users/$info{'node'}");
      telechannel($prevchan);
      loaduser($info{'id'});
      goto channel;
      }
    }
    telesend();
  }
  goto telemain;
  leave: {
    last;
    $plcholder="1";
  }
 }
}

sub telesend {
  $sendmessage=$_[0];
  @telesendto=`ls $config{'home'}$config{'messages'}/teleconf/$chanid/users 2>/dev/null`;
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
   @activenodes=<$config{'home'}$config{'nodes'}/*>;
   foreach $node(@activenodes) {
     lockfile("$node");
     open(in,"<$node");
     $nodeinfo=<in>;
     close(in);
     unlockfile("$node");
     chomp ($nodeinfo);
     ($discard,$discard,$discard,$discard,$person,$discard,$discard)=split(/\|/,$nodeinfo);
     push(@usersonline,$person);
   }

   foreach $user(@usersonline) {
     chomp ($user);
     if ($user eq "CONNECT") {
       next;
     }

     $pguser=uc($pguser);
     $user=uc($user);
     if ($pguser eq $user) {
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

      ($discard,$pnode,$discard,$discard,$person,$discard,$discard)=split(/\|/,$nodeinfo);
      writeline($YLW."You whispered to $person: ".$pmsg,1);
      lockfile("$config{'home'}$config{'messages'}/$pnode.page");
      open (out,">>$config{'home'}$config{'messages'}/$pnode.page");
      print out "\@YLW".$info{'handle'}."\@YLW whispers\@LTB: \@WHT".$pmsg."\n";
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
  @channels=();
  lockfile("$config{'home'}$config{'messages'}/teleconf/channels");
  if ( -e "$config{'home'}$config{'messages'}/teleconf/channels" ) {
    open (in,"<$config{'home'}$config{'messages'}/teleconf/channels");
    @channels=<in>;
    close(in);
  }
  unlockfile("$config{'home'}$config{'messages'}/teleconf/channels");

  writeline("",1);

format chanscan =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  .....  @<<<<<<<<<<< @<<<<<
$channelname,$chanstat,$chanusers
.

  $channelname="Channel .....";$chanstat="Status";$chanusers="Users";
  writeline($YLW);
  $~="chanscan";
  write;
  $~="stdout";
  writeline($LTB);

  foreach $chan(@channels) {
   $chanenc="";
   $chanstat="";
   chomp ($chan);
   ($chanid,$chanown,$channelname) = split(/\|/,$chan);
   if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
     unless ($info{'security'} ge $config{'chanop'}) {
       next;
     }
     $chanstat=" (H)";
   }
   if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
     $chanstat="PRIVATE".$chanstat;
   } else {
     $chanstat="PUBLIC".$chanstat;
   }
   @scanchanusr=<$config{'home'}$config{'messages'}/teleconf/$chanid/users/*>;
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
@<<< @<<<<<<<<<<<<<<<  .....  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
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
    $whonode=sprintf("%03D",$whonode);
    $~="telescan";
    lockfile("$config{'home'}$config{'messages'}/teleconf/channels");
    if ( -e "$config{'home'}$config{'messages'}/teleconf/channels" ) {
      open (in,"<$config{'home'}$config{'messages'}/teleconf/channels");
      @channels=<in>;
      close(in);
    }
    unlockfile("$config{'home'}$config{'messages'}/teleconf/channels");

    if (-e "$config{'home'}$config{'messages'}/teleconf/$whowhere/hidden") {
      $whowhere="*******"
    } else {
      foreach $channel(@channels) {
        chomp ($channel);
        ($schanid,$schanowner,$schanname)=split(/\|/,$channel);
        if ($schanid eq $whowhere) {
          $whowhere = $schanname;
          last;
        }
      }
    }
    @channels=();
    write;
    $~="stdout";
  }
  writeline($RST."\n");
}


return 1;
