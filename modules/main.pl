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
    print out "\n\@DATACLR[\@USERCLR".$info{'handle'}."\@DATACLR] \@SYSTEMCLR".$msg."\n";
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
        $channel=$channelname;
        last;
      }
    }

    if ($chanexists eq 0) {
      if ($info{'security'} ge $config{'sec_createchan'}) {
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

        writeline($BWH."\nCreating channel ".$config{'usercolor'}.$channel.$BWH." ..",1);
        writeline($BWH."Assigned ".$config{'usercolor'}.$info{'handle'}.$BWH." as owner ..",1);
      } else {
        writeline($BWH."\nYou are not authorized to create channels.",1);
        unlockfile("$config{'home'}$config{'messages'}/teleconf/channels");
        $canjoin=0;
        writeline($BWH."Entering channel ".$config{'usercolor'}.$config{'defchannel'},1);
        telechannel($config{'defchannel'});
      }
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


  unless ($ops eq 1 || $info{'security'} ge $config{'sec_chanop'}) {
    if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/banned") {
      lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      open (in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       @chanban=<in>;
      close (in);
      unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      foreach $item(@chanban) {
        chomp $item;
        if ($item eq $info{'handle'}) {
          writeline ($BWH."You are not allowed to join ".$config{'usercolor'}.$channel.$BWH." ..",1);
          writeline($BWH."Entering channel ".$config{'usercolor'}.$config{'defchannel'},1);
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
  unless ($op eq 1 || $info{'security'} ge $config{'sec_chanop'}) {
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
      writeline ($BWH."You are not allowed to enter channel ".$config{'usercolor'}.$channel.$BWH." ..",1);
      $canjoin=0;
      writeline($BWH."Entering channel ".$config{'usercolor'}.$config{'defchannel'},1);
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

  iamat($info{'handle'},"Chat");

  $leaving="1";
  unless ($rescan eq "1") {
    logger("NOTICE: ".$info{'handle'}." joined ".$chanid);
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
    writeline ($BWH."Joining the ".$config{'datacolor'}.$config{'defchannel'}.$BWH." channel ..");
    telechannel($config{'defchannel'});
  } else {
    writeline ($BWH."Joining the ".$config{'datacolor'}.$info{'defchan'}.$BWH." channel ..");
    telechannel($info{'defchan'});
  }
  if ( $config{'systemname'} ) {
    writeline ($config{'usercolor'}."\n\n".$config{'systemname'},1);
  } else {
    writeline ("\n\n");
  }
 channel: {
  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
    $private=" (".$config{'datacolor'}."PRIVATE".$config{'themecolor'}.")";
  } else {
    $private="";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
    $private=$private." (".$config{'datacolor'}."ENC".$config{'themecolor'}.")";
  }

  if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/message") {
    $inteleconf=0;
    readfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message",1,1);
    $inteleconf=1;
    writeline($RST,1);
  }

  writeline ($config{'themecolor'}."You are in the ".$config{'datacolor'}.$channel.$config{'themecolor'}." channel".$private.".\n".$RST.$channelusers."\n");

  if ($channel =~/$config{'defchannel'}/) {
    writeline($config{'usercolor'}."Press \"".$config{'datacolor'}.$config{'help'}.$config{'usercolor'}."\" for a list of commands.\n");
  }

  telemain: {
    loaduser($info{'id'});
    if ($info{'banned'} eq "Y") {
      $leaving="1";
      telesend("was banned from the system!");
      writeline($config{'errorcolor'}."You have been banned from this system, disconnecting.");
      $leaving="0";
      $atmenu="0";
      $inteleconf="0";
      $info{'dnd'}=$dndmode;
      unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/users/$info{'node'}");
      goto leave;
    }

    writeline($RST.$config{'inputcolor'}.$config{'promptchr'}." ");
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
        writeline ($BWH."Can not hide the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }
      if ($info{'handle'} eq $chanown) {
        unless (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
          writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." hidden ..",1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
          open (out,">$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
           print out "1";
          close (out);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/hidden");
        } else {
          writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." is no longer hidden ..",1);
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
           writeline($BWH."Reset  ".$config{'datacolor'}.$config{'defchannel'}.$BWH." as your favorite.",1);
           $info{'defchan'}=$config{'defchannel'};
        } else {
           writeline($BWH."Saved ".$config{'datacolor'}.$channel.$BWH." as your favorite.",1);
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
      writeline($BWH."Unknown ".$config{'usercolor'}."SET".$BWH." command",1);
      goto telemain;
    }

    if ($chatline =~/^\/[Bb][Aa][Nn]\ / || $chatline =~/^\/[Bb]\ /) {
      ($junk,$banuser)=split(/\s/,$chatline);

      $banuser=lc($banuser);

      if ($banuser eq "") {
        writeline ($BWH."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($BWH."Can not (un)ban users in the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
       $unallned=0;
       if ($banuser eq $info{'handle'}) {
         writeline ($BWH."You can not ban yourself from a channel ..", 1);
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
             writeline ($BWH."User ".$config{'usercolor'}.$banuser.$BWH." is no longer banned from ".$config{'usercolor'}.$channel.$BWH." ..",1);
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
       writeline ($BWH."User ".$config{'usercolor'}.$banuser.$BWH." now banned from ".$config{'usercolor'}.$channel.$BWH." ..",1);
       lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
        print out $banuser."\n";
       close (out);
       unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
       goto telemain;
     } else {
       goto telemain;
     }


     writeline ($BWH."User ".$config{'usercolor'}.$banuser.$BWH." no longer banned from entering ".$config{'usercolor'}.$channel.$BWH." ..",1);
     lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
     open (out,">>$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
      print out $banuser."\n";
     close (out);
     unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
     goto telemain;
    }

    if ($chatline =~/^\/[Ss][Tt][Aa][Tt][Uu][Ss]$/i || $chatline =~/^\/\$$/ || $chatline =~/^\$$/) {
      if ($op eq 1 || $info{'security'} ge $config{'sec_chanop'}) {
        writeline($BWH."\nSystem report for channel: ".$config{'datacolor'}.$channel.$BWH."\n",1);
        writeline($config{'datacolor'}."Channel Owner: ".$config{'themecolor'}.$chanown,1);
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/banned") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/banned");
          writeline($config{'datacolor'}."Banned users: ");
          if (scalar(@rep) gt 0) {
            foreach $brep(@rep) {
              chomp $brep;
              unless ($brep =~/$info{'handle'}/) {
                writeline($config{'themecolor'}.$brep." ");
              }
            }
            writeline($RST,1);
          } else {
            writeline($config{'themecolor'}."None",1);
          }
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
          writeline($config{'datacolor'}."Room is ".$config{'themecolor'}."PRIVATE".$RST,1);
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
          writeline($config{'datacolor'}."Allowed users: ");
          if (scalar(@rep) gt 1) {
            foreach $brep(@rep) {
              chomp $brep;
              unless ($brep =~/$info{'handle'}/) {
                writeline($config{'themecolor'}.$brep." ");
              }
            }
            writeline($RST,1);
          } else {
            writeline($config{'themecolor'}."None",1);
          }
        } else {
          writeline($config{'datacolor'}."Room is ".$config{'themecolor'}."PUBLIC",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ops") {
          lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          open(in,"<$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
            @rep=<in>;
          close(in);
          unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/ops");
          writeline($config{'datacolor'}."Channel Operators: ");
          if (scalar(@rep) gt 0) {
            foreach $brep(@rep) {
              chomp $brep;
              writeline($config{'themecolor'}.$brep." ");
            }
            writeline($RST,1);
          } else {
            writeline($config{'themecolor'}."None",1);
          }
        } else {
          writeline($config{'datacolor'}."There are no channel ops other than its owner",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
          writeline($config{'datacolor'}."This room is ".$config{'themecolor'}."HIDDEN FROM".$config{'datacolor'}." channel scans",1);
        } else {
          writeline($config{'datacolor'}."This room is ".$config{'themecolor'}."SHOWN IN".$config{'datacolor'}." channel scans",1);
        }

        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
          writeline($config{'datacolor'}."This room requires ".$config{'themecolor'}."SSH".$config{'datacolor'}." connections",1);
        } else {
          writeline($config{'datacolor'}."This room is open to ".$config{'themecolor'}."UNENCRYPTED".$config{'datacolor'}." connections",1);
        }

        goto telemain;
      } else {
        writeline ($BWH."You are not a chanop",1);
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Tt][Oo][Pp][Ii][Cc]/ || $chatline =~/^\/[Tt]/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($BWH."Can not change the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown || $info{'security'} ge $config{'sec_chanop'}) {
        lockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message");
        system("nano -R $config{'home'}$config{'messages'}/teleconf/$chanid/message");
        unlockfile("$config{'home'}$config{'messages'}/teleconf/$chanid/message");
        writeline($BWH."Set Channel message ..",1);
        goto channel;
      } else {
        goto telemain;
      }
    }

    if ($chatline =~/^\/[Pp][Rr][Ii][Vv][Aa][Tt][Ee]$/ || $chatline =~/^\/[Vv]$/) {
      if ($channel eq $config{'defchannel'}) {
        writeline ($BWH."Can not change the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/allow") {
          writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." is now ".$config{'datacolor'}."PUBLIC".$BWH."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/allow");
        } else {
  	      writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." is now ".$config{'datacolor'}."PRIVATE".$BWH."..",1);
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
        writeline ($BWH."Can not change the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
        if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/ssh") {
          writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." is now ".$config{'datacolor'}."UNENCRYPTED OK".$BWH."..",1);
          unlink ("$config{'home'}$config{'messages'}/teleconf/$chanid/ssh");
        } else {
         unless ($info{'proto'} =~/SSH/) {
           writeline ($config{'errorcolor'}."Warning: Can not change channel properties; you are connected via ".$config{'datacolor'}.$info{'proto'}.$config{'errorcolor'}."..",1);
           writeline("",1);
           goto channel;
         }
         writeline ($BWH."Channel ".$config{'usercolor'}.$channel.$BWH." is now ".$config{'datacolor'}."ENCRYPT ONLY".$BWH."..",1);
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

      if ($opuser =~/$info{'handle'}/ && $info{'security'} ge $config{'sec_chanop'}) {
        writeline ($BWH."You can not un-op yourself ".$info{'handle'}." ..",1);
        $opuser = "";
      }

      if ($opuser eq "") {
        writeline ($BWH."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'} || $info{'security'} lt $config{'sec_sysop'}) {
        writeline ($BWH."Can not change ChanOP users in the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
        $unallned=0;
        if ($opuser eq $info{'handle'}) {
          writeline ($BWH."You can not remove ChanOP from yourself ..", 1);
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
              writeline ($BWH."User ".$config{'usercolor'}.$opuser.$BWH." is no longer ChanOP in channel ".$config{'usercolor'}.$channel.$BWH." ..",1);
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
        writeline ($BWH."User ".$config{'usercolor'}.$opuser.$BWH." ChanOP of channel ".$config{'usercolor'}.$channel.$BWH." ..",1);
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
        writeline ($BWH."You can not unallow yourself ".$info{'handle'}." ..",1);
        $alluser = "";
      }

      if ($alluser eq "") {
        writeline ($BWH."Action cancelled ..",1);
        goto telemain;
      }

      if ($channel eq $config{'defchannel'}) {
        writeline ($BWH."Can not (un)allow users in the ".$config{'usercolor'}.$config{'defchannel'}.$BWH." channel ..",1);
        goto telemain;
      }

      if ($info{'handle'} eq $chanown) {
        $unallned=0;
        if ($alluser eq $info{'handle'}) {
          writeline ($BWH."You can not unallow yourself from a channel ..", 1);
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
              writeline ($BWH."User ".$config{'usercolor'}.$alluser.$BWH." is no longer allowed to enter ".$config{'usercolor'}.$channel.$BWH." ..",1);
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
        writeline ($BWH."User ".$config{'usercolor'}.$alluser.$BWH." now allowed to enter ".$config{'usercolor'}.$channel.$BWH." ..",1);
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
      writeline($BWH."Entering channel ".$config{'usercolor'}.$channel.$BWH." ...\n",1);
      telechannel($channel);
      goto channel;
    }

    if ($chatline =~/^\/[Ww]\ / || $chatline =~/^\/[Ww][Hh][Ii][Ss][Pp][Ee][Rr]\ /) {
      ($jnk,$data)=split(/\s/,$chatline,2);
      telewhisper($data);
      goto telemain;
    }

    if ($chatline =~/^\/[Rr]\ / || $chatline =~/^\/[Bb][Rr][Oo][Aa][Dd][Cc][Aa][Ss][Tt]\ /) {
      if ($info{'security'} ge $config{'sec_chanop'}) {
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

      $chatline =~s/\@BGN/$config{'themecolor'}/g;
      $chatline =~s/\@BYL/$config{'usercolor'}/g;
      $chatline =~s/\@BBL/$config{'datacolor'}/g;
      $chatline =~s/\@RST/$RST/g;
      $chatline =~s/\@BLK/$BLK/g;
      $chatline =~s/\@RED/$RED/g;
      $chatline =~s/\@GRN/$GRN/g;
      $chatline =~s/\@YLW/$YLW/g;
      $chatline =~s/\@BLU/$BLU/g;
      $chatline =~s/\@MAG/$MAG/g;
      $chatline =~s/\@WHT/$WHT/g;
      $chatline =~s/\@CYN/$CYN/g;
      $chatline =~s/\@BBK/$BBK/g;
      $chatline =~s/\@BRD/$BRD/g;
      $chatline =~s/\@BGN/$BGN/g;
      $chatline =~s/\@BYL/$BYL/g;
      $chatline =~s/\@BMG/$BMG/g;
      $chatline =~s/\@BCN/$BCN/g;
      $chatline =~s/\@BWH/$BWH/g;
      telesend($chatline);
      goto telemain;
    }
    if ($chatline =~/^[Xx]$/ || $chatline =~/^\/[Qq][Uu][Ii][Tt]$/ || $chatline =~/^[Ee][Xx][Ii][Tt]$/) {
      writeline($theme{'exita'}.$theme{'exitb'}." ");
      $choice=waitkey("N");
      if ($choice =~/[Yy]/) {
        writeline ($BWH."\nLogging off..",1);
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
        writeline($BWH.$info{'handle'}." ".$mdesc,1);
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
        $idle=time;
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
      writeline ($config{'themecolor'}."There is no one here with you!",1);
    }
  } else {
    foreach $channode(@telesendto) {
      chomp ($channode);
      if ($leaving eq "1") {
        if ($channode eq $info{'node'}) {
          next;
        }
      }
      $chatline =~s/\@SYSTEMCLR/$config{'systemcolor'}/g;
      $chatline =~s/\@USERCLR/$config{'usercolor'}/g;
      $chatline =~s/\@INPUTCLR/$config{'inputcolor'}/g;
      $chatline =~s/\@ERRORCLR/$config{'errorcolor'}/g;
      $chatline =~s/\@THEMECLR/$config{'themecolor'}/g;
      $chatline =~s/\@PROMPTCLR/$config{'promptcolor'}/g;
      $chatline =~s/\@DATACLR/$config{'datacolor'}/g;
      $chatline =~s/\@LINECLR/$config{'linecolor'}/g;
      $chatline =~s/\@BGN/$BGN/g;
      $chatline =~s/\@BYL/$BYL/g;
      $chatline =~s/\@BBL/$BBL/g;
      $chatline =~s/\@RST/$RST/g;
      $chatline =~s/\@BLK/$BLK/g;
      $chatline =~s/\@RED/$RED/g;
      $chatline =~s/\@GRN/$GRN/g;
      $chatline =~s/\@YLW/$YLW/g;
      $chatline =~s/\@BLU/$BLU/g;
      $chatline =~s/\@MAG/$MAG/g;
      $chatline =~s/\@WHT/$WHT/g;
      $chatline =~s/\@CYN/$CYN/g;
      $chatline =~s/\@BBK/$BBK/g;
      $chatline =~s/\@BRD/$BRD/g;
      $chatline =~s/\@BGN/$BGN/g;
      $chatline =~s/\@BYL/$BYL/g;
      $chatline =~s/\@BMG/$BMG/g;
      $chatline =~s/\@BCN/$BCN/g;
      $chatline =~s/\@BWH/$BWH/g;

      $sendmessage =~s/\@SYSTEMCLR/$config{'systemcolor'}/g;
      $sendmessage =~s/\@USERCLR/$config{'usercolor'}/g;
      $sendmessage =~s/\@INPUTCLR/$config{'inputcolor'}/g;
      $sendmessage =~s/\@ERRORCLR/$config{'errorcolor'}/g;
      $sendmessage =~s/\@THEMECLR/$config{'themecolor'}/g;
      $sendmessage =~s/\@PROMPTCLR/$config{'promptcolor'}/g;
      $sendmessage =~s/\@DATACLR/$config{'datacolor'}/g;
      $sendmessage =~s/\@LINECLR/$config{'linecolor'}/g;
      $sendmessage =~s/\@BGN/$BGN/g;
      $sendmessage =~s/\@BYL/$BYL/g;
      $sendmessage =~s/\@BBL/$BBL/g;
      $sendmessage =~s/\@RST/$RST/g;
      $sendmessage =~s/\@BLK/$BLK/g;
      $sendmessage =~s/\@RED/$RED/g;
      $sendmessage =~s/\@GRN/$GRN/g;
      $sendmessage =~s/\@YLW/$YLW/g;
      $sendmessage =~s/\@BLU/$BLU/g;
      $sendmessage =~s/\@MAG/$MAG/g;
      $sendmessage =~s/\@WHT/$WHT/g;
      $sendmessage =~s/\@CYN/$CYN/g;
      $sendmessage =~s/\@BBK/$BBK/g;
      $sendmessage =~s/\@BRD/$BRD/g;
      $sendmessage =~s/\@BGN/$BGN/g;
      $sendmessage =~s/\@BYL/$BYL/g;
      $sendmessage =~s/\@BMG/$BMG/g;
      $sendmessage =~s/\@BCN/$BCN/g;
      $sendmessage =~s/\@BWH/$BWH/g;

      lockfile("$config{'home'}$config{'messages'}/$channode.page");
      open(out,">>$config{'home'}$config{'messages'}/$channode.page");
       unless (defined($sendmessage)) {
         print out "\@USERCLR".$info{'handle'}."\@DATACLR".": "."\@INPUTCLR".$chatline."\@INPUTCLR"."\n";
       } else {
         print out "\@INPUTCLR".$info{'handle'}." ".$sendmessage."\@INPUTCLR"."\n";
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

     $pguser=lc($pguser);
     $user=lc($user);
     if ($pguser eq $user) {
        $found=1;
        $pmsg=join(' ',@parts);
     }

     if ($found eq "1") {
       $pmsg =~s/\@SYSTEMCLR/$config{'systemcolor'}/g;
       $pmsg =~s/\@USERCLR/$config{'usercolor'}/g;
       $pmsg =~s/\@INPUTCLR/$config{'inputcolor'}/g;
       $pmsg =~s/\@ERRORCLR/$config{'errorcolor'}/g;
       $pmsg =~s/\@THEMECLR/$config{'themecolor'}/g;
       $pmsg =~s/\@PROMPTCLR/$config{'promptcolor'}/g;
       $pmsg =~s/\@DATACLR/$config{'datacolor'}/g;
       $pmsg =~s/\@LINECLR/$config{'linecolor'}/g;
       $pmsg =~s/\@RST/$RST/g;
       $pmsg =~s/\@BLK/$BLK/g;
       $pmsg =~s/\@RED/$RED/g;
       $pmsg =~s/\@GRN/$GRN/g;
       $pmsg =~s/\@YLW/$YLW/g;
       $pmsg =~s/\@BLU/$BLU/g;
       $pmsg =~s/\@MAG/$MAG/g;
       $pmsg =~s/\@WHT/$WHT/g;
       $pmsg =~s/\@CYN/$CYN/g;
       $pmsg =~s/\@BBK/$BBK/g;
       $pmsg =~s/\@BRD/$BRD/g;
       $pmsg =~s/\@BGN/$BGN/g;
       $pmsg =~s/\@BYL/$BYL/g;
       $pmsg =~s/\@BMG/$BMG/g;
       $pmsg =~s/\@BCN/$BCN/g;
       $pmsg =~s/\@BWH/$BWH/g;

      ($discard,$pnode,$discard,$discard,$person,$discard,$discard)=split(/\|/,$nodeinfo);
      writeline($config{'usercolor'}."You whispered to $person: ".$pmsg,1);
      lockfile("$config{'home'}$config{'messages'}/$pnode.page");
      open (out,">>$config{'home'}$config{'messages'}/$pnode.page");
      print out "\@USERCLR".$info{'handle'}."\@USERCLR whispers\@DATACLR: \@SYSTEMCLR".$pmsg."\n";
      close (out);
      unlockfile("$config{'home'}$config{'messages'}/$pnode.page");
      writeline($RST,1);
      last;
    }
  }
  if ($found ne "1") {
    writeline($config{'datacolor'}.$pguser.$config{'datacolor'}." is not online",1);
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
  writeline($config{'themecolor'});
  $~="chanscan";
  write;
  $~="stdout";
  writeline($config{'datacolor'});

  foreach $chan(@channels) {
   $chanenc="";
   $chanstat="";
   chomp ($chan);
   ($chanid,$chanown,$channelname) = split(/\|/,$chan);
   if (-e "$config{'home'}$config{'messages'}/teleconf/$chanid/hidden") {
     unless ($info{'security'} ge $config{'sec_chanop'}) {
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

  writeline($config{'datacolor'});
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
  writeline("\n");

format telescan =
@<<< @<<<<<<<<<<<<<<<  .....  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$whonode,$whouser,$whowhere
.
  writeline($config{'systemcolor'});
  $whonode="Node"; $whouser="User-ID"; $whowhere="Channel";
  $~="telescan";
  write;
  $~="stdout";
  writeline($config{'datacolor'});
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
