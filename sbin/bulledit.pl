#!/usr/bin/perl
# 
#  User manager for PhotonBBS
#  (C) 2009 Andrew Wyatt
#  GNU GPL v2
#

$texteditor="nano";

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
$sysinfo{'version'}="1.8";
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

$info{'ansi'}=$fusiondoor{'ansi'};
if ($fusiondoor{'ansi'} eq "1") {
  $info{'ext'}="ans";
} else {
  $info{'ext'}="asc";
}
colorize();

for (;;) {
  bullmenu: {
    $inteleconf=0;
    iamat($info{'handle'},"Bulletin Editor");
    $count=1;

    ###
    ### bulletins.xxx should contain the index
    ### if it doesn't exist, generate a menu
    ###

    $bullidx=$config{'home'}.$config{'data'}."/bullidx.dat";
    lockfile("$bullidx");
    open (in,"<$bullidx");
    @bulls=<in>;
    close (in);
    unlockfile("$bullidx");

    print "\e[2J\e[0;0H";
    writeline ($WHT.$sysinfo{'servername'}." ".$sysinfo{'version'},1);
    writeline ($LGN."Bulletin Editor - ".$BLU." [ ".$WHT.scalar(@bulls).$BLU." ]\n",1);

    unless($readit eq 1) {
      for (0..scalar(@bulls)) {
        $bulln=$_+1;
        chomp ($bulls[$_]);
        ($bullid,$bulltxt)=split(/\|/,$bulls[$_]);
        if ($bulltxt ne "") {
          writeline($LTB.$bulln.$YLW." ...".$LGN." ".$bulltxt,1);
        }
      }
    }
    writeline ($LGN."\nEnter \"".$LTB."#".$LGN."\" to edit / Delete a bulletin, \"".$LTB."N".$LGN."\"ew, or \"".$LTB."Q".$LGN."\"uit: ");

    $result=getline(text,2,"",1);
    unless ($result =~/^[Qq]$/) {

      if ($result =~/[0-9]/i) {
        writeline ($LGN."Would you like to, or \"".$LTB."E".$LGN."\"dit or \"".$LTB."D".$LGN."\"elete this bulletin: ");

        $key="";
        cbreak(on);
        $key=waitkey();
        cbreak(off);
 
        writeline("",1);

        $result=$result-1;
        if ($result lt 0) {
          $result=0;
        }

        if ($key =~/^[Ee]$/) {
          if ($bulls[$result] ne "") {
            ($bullid,$bulltxt)=split(/\|/,$bulls[$result]);
            if (-e "$config{'home'}/$config{'text'}/$bullid") {
              system ("$texteditor $config{'home'}/$config{'text'}/$bullid");
              goto bullmenu;
            }
          }
        }

        if ($key =~/^[Dd]$/) {
          writeline ($LGN."Are you sure? (y/N): ");

          $key="";
          cbreak(on);
          $key=waitkey();
          cbreak(off);
          writeline("",1);

          unless ($key =~/^[Yy]$/) {
            goto bullmenu;
          }

          if ($bulls[$result] ne "") {
            ($bullid,$bulltxt)=split(/\|/,$bulls[$result]);
            if (-e "$config{'home'}/$config{'text'}/$bullid") {
              unlink("$config{'home'}/$config{'text'}/$bullid");
            }

            $removing = $bulls[$result];
            %tmpbulls = map { $_ => "1" } @bulls;
            delete $tmpbulls{$removing};
            @bulls = keys %tmpbulls;
            undef %tmpbulls;
            lockfile("$bullidx");
            open (newbull,">$bullidx");
            foreach $bull(@bulls) {
              chomp $bull;
              if ($bull ne "") {
                print newbull $bull."\n";
              }
            }
            close (newbull);
            unlockfile("$bullidx");
            writeline($RED."Bulletin Deleted.")
          }
        }
        goto bullmenu;
      }

      if ($result =~/^[Nn]$/) {
        $newtopic=getline(text,71,"\n".$LGN."Title: ");
        if ($newtopic eq "") {
          goto bullmenu;
        }
        $newbull=scalar(@bulls)-1;
        getnewbull: {
          $newbull=int(rand(100000)*100);
          while ( -e "$config{'home'}/$config{'text'}/bull".$newbull.".txt") {
            goto getnewbull;
          }
        }
        $newbullid="bull".$newbull.".txt";
        push (@bulls,$newbullid."|".$newtopic);
        system ("$texteditor $config{'home'}/$config{'text'}/$newbullid");
        if (-e "$config{'home'}/$config{'text'}/$newbullid") {
          lockfile("$bullidx");
          open (newbull,">$bullidx");
          foreach $bull(@bulls) {
            chomp $bull;
            if ($bull ne "") {
              print newbull $bull."\n";
            }
          }
          close (newbull);
          unlockfile("$bullidx");
        }
        goto bullmenu;
      }
    } else {
      exit 0;
    }
    writeline("\n");
  }
}
