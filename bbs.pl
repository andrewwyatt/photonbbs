#!/usr/bin/perl

#    PhotonBBS -- Simple BBS / Chat server for *nix
#    Copyright (C) 2002-2013, Andrew Wyatt
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

### Add a set of defaults in-case /etc/default/photonbbs does not exist
### or it does not contain all of the necessary variables.

$config{'home'}="/opt/photonbbs";          ## Main BBS Path (many dependencies on this)
$config{'bin'}="/bin";                     ## BBS Bin path (Future use)
$config{'data'}="/data";                   ## BBS Data path
$config{'messages'}="/data/messages";      ## Pager / Teleconference message path
$config{'nodes'}="/data/nodes";            ## Node information path
$config{'text'}="/data/text";              ## Ansi & BBS text files
$config{'themes'}="/data/themes";          ## BBS Skin file
$config{'users'}="/data/users";            ## User information path
$config{'sbin'}="/sbin";                   ## Script bin -> Path to door scripts
$config{'doors'}="/opt/photonbbs/doors";   ## Node info -> Drop files etc
$config{'help'}="?";                       ## Key to press for help
$config{'authretries'}="3";                ## Number of password retries
$config{'passlength'}="30";                ## Password length
$config{'passchr'}="*";                    ## Passchr to echo at password prompt
$config{'promptchr'}=":";                  ## Conference prompt character
$config{'theme'}="photon";                 ## Default Skin
$config{'public'}="1";                     ## Public(1)/Private(0) BBS
$config{'systemcolor'}='@WHT';             ## System text color
$config{'usercolor'}='@BWH';               ## User notification color
$config{'inputcolor'}='@WHT';              ## User input color
$config{'themecolor'}='@BBL';              ## Prompt text color
$config{'promptcolor'}='@WHT';             ## Prompt text color
$config{'errorcolor'}='@RED';              ## Color for error messages
$config{'datacolor'}='@BWH';               ## Generated data color
$config{'linecolor'}='@BLU';               ## Line color (Oneliners, etc)
$config{'usefullname'}="1";                ## Force Full Name Yes(1) / No (0)
$config{'usephonenum'}="0";                ## Force User's phone number Yes(1) / No (0)
$config{'systemname'}="Photon BBS";        ## BBS's Name
$config{'clearlogin'}="0";                 ## Clear screen before displaying header
$config{'headers'}="1";                    ## Display BBS name on connect
$config{'sysop'}="SysOp";                  ## Sysop's Name
$config{'host'}="";                        ## Override SysInfo Hostname with cname
$config{'oneliners'}="1";                  ## Enable Oneliners
$config{'bulletins'}="1";                  ## Enable System Bulletins
$config{'onelinerrows'}="15";              ## Number of oneliners to keep
$config{'lastcallers'}="25";               ## Keep this many last callers in the list
$config{'lastcallenable'}="1";             ## Last Callers Enable (1) / Disable (0)
$config{'unixuser'}="bbs";                 ## User account the application runs as
$config{'sec_user'}="10";                  ## Default Sec level for new users
$config{'sec_createchan'}="100";           ## Minimum security level to create new channels
$config{'sec_chanop'}="100";               ## Teleconference Admin security level (System wide ChanOP)
$config{'sec_sysop'}="500";                ## Level to become a sysop
$config{'defchannel'}="MAIN";              ## Default Teleconference Channel
$config{'deftheme'}="photon";              ## Default User selected skin
$config{'totalnodes'}="99";                ## Support this many nodes.
$config{'rows'}="24";                      ## Number of rows before prompting to continue / quit
$config{'buffer'}="255";                   ## Chat line buffer size (255 characters recommended)
$config{'idledisconnect'}="900";           ## Idle time (in seconds) before being disconnected
$config{'facility'}="daemon.notice";       ## Log facility for syslog messages
$config{'slackintegration'}="0";           ## Send notifications to a Slack channel
$config{'slackerrors'}="0";                ## Sends error messages to your slack channel
$config{'slackwarnings'}="0";              ## Sends warning messages to your slack channel
$config{'slackuser'}="Photon BBS";         ## Send notifications from this user
$config{'slackchannel'}="";                ## Send notifications to this channel
$config{'slackemoji'}="";                  ## Use this emoji for notifications
$config{'slackapipath'}="";                ## This is the Slack API token for your webhook

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
}

unless ( $config{'host'} ne "" ) {
  chomp ($sysinfo{'host'}=`hostname -f`);
}
chomp ($sysinfo{'os'}=`uname -s`);
chomp ($sysinfo{'ip'}=`hostname -i`);
###

$|=1;
$BSD_STYLE=1;

require ($config{'home'}."/modules/framework.pl");
require ($config{'home'}."/modules/usertools.pl");
require ($config{'home'}."/modules/main.pl");
require ($config{'home'}."/modules/doors.pl");
require	($config{'home'}."/modules/lastcallers.pl");
require ($config{'home'}."/modules/oneliners.pl");

chomp ($mytty=`tty`);

main: {
  $SIG{KILL}=sub {errorout ("SIGKILL..");};
  $SIG{HUP}=sub {errorout ("SIGHUP..");};
  $SIG{TERM}=sub {errorout ("SIGTERM..");};
  $SIG{QUIT}=sub {errorout ("SIGQUIT..");};

  $debug=1;
  hi();
  logger("NOTICE: Connection from ".$info{'connect'}." via ".$info{'proto'});
  colorize();
  applytheme($config{'theme'});
  cbreak(on);
  begin: {
    if (-e "$config{'home'}$config{'text'}/welcome.$info{'ext'}") {
      readfile("welcome.$info{'ext'}");
      $readit=1;
    }
    if (-e "$config{'home'}$config{'text'}/welcome.txt" && $readit ne "1") {
      readfile("welcome.txt");
      $readit=1;
    }
    authenticate();
    if ($info{'banned'} eq "Y") {
        logger("NOTICE: ".$info{'handle'}." is banned, terminating.");
        writeline($theme{'banned'});
        bye();
    }

  }
  iamat($info{'handle'},"Heading to Chat");

  $readit=0;
  if (-e "$config{'home'}$config{'text'}/login.txt") {
     readfile("login.txt");
     $readit=1;
   }
   if (-e "$config{'home'}$config{'text'}/login.$info{'ext'}" && $readit ne "1") {
     readfile("login.$info{'ext'}");
     $readit=1;
   }
  applytheme($config{'theme'});
  lastcallers();

  bulletins();
  oneliners();
  setupdoors();
  iamat($info{'handle'},"Logging in");
  whosonline();
  iamat($info{'handle'},"Chat");
  logger("NOTICE: ".$info{'handle'}." entered teleconference");
  teleconf();
  bye();
}
