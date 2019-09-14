#!/usr/bin/perl

sub oneliners{
if ($config{'oneliners'} ne "0") {
  oneliner: {
    $inteleconf=0;
    iamat($info{'handle'},"OneLiners");

    if (-e "$config{'home'}$config{'text'}/oneliner") {
      $readit=0;
      if (-e "$config{'home'}$config{'text'}/oneltop.$info{'ext'}") {
        readfile("oneltop.$info{'ext'}");
        $readit=1;
      } elsif (-e "$config{'home'}$config{'text'}/oneltop.txt" && $readit ne "1") {
        readfile("oneltop.txt");
        $readit=1;
      }else {
        writeline("\n".$theme{'oneltop'}."\n\n");
      }
      lockfile("$config{'home'}$config{'text'}/oneliner");
      open (onlin,"<$config{'home'}$config{'text'}/oneliner");
        while (<onlin>) {
         $oneliner=$_;
         chomp $oneliner;
         ($olid,$oline)=split(/\|/,$oneliner);
         if ($olid eq "") {
           $olname="confucius";
         } else {
           $olname=getuname($olid);
         }
         $oline=colorline("$oline");
         writeline("  ".$config{'systemcolor'}.$olname." ".$config{'usercolor'}."says".$config{'promptcolor'}.": ".$config{'themecolor'}.$oline,1);
        }
      close(onlin);
      unlockfile("$config{'home'}$config{'text'}/oneliner");

      $readit=0;
      if (-e "$config{'home'}$config{'text'}/onelbot.$info{'ext'}") {
        readfile("onelbot.$info{'ext'}");
        $readit=1;
      } elsif (-e "$config{'home'}$config{'text'}/onelbot.txt" && $readit ne "1") {
        readfile("onelbot.txt");
        $readit=1;
      }else {
        writeline($theme{'onelbot'});
      }
    } else {
      writeline($theme{'onelemp'},1);
    }
    writeline($theme{'onelcol'}." ");
    $oneliner{'yn'}=waitkey("N");
    if (uc($oneliner{'yn'}) eq "Y") {
      $oneliner{'blah'}=getline(text,50,$theme{'onelask'});
      if ($oneliner{'blah'} eq "") {
        writeline("\n");
        $inteleconf=1;
        return;
      }
      $oneliner{'blah'}=colorline("$oneliner{'blah'}");
      writeline($theme{'oneltel'}.$oneliner{'blah'},1);
      writeline($theme{'onelhap'});
      $oneliner{'yn'}=waitkey("Y");
      unless (uc($oneliner{'yn'}) =~/Y/) {
        writeline("\n");
        goto oneliner;
      }
      writeline($theme{'onelsig'});
      $oneliner{'sign'}=waitkey("Y");
      if (-e "$config{'home'}$config{'text'}/oneliner") {
        lockfile("$config{'home'}$config{'text'}/oneliner");
        open (in,"<$config{'home'}$config{'text'}/oneliner");
          @oneliners=<in>;
        close(in);
        unlockfile("$config{'home'}$config{'text'}/oneliner");

        $onlkeep=$config{'onelinerrows'};
        --$onlkeep;
        unless (scalar(@oneliners) <= "$onlkeep") {
          until (scalar(@oneliners) == "$onlkeep") {
            $junk=shift(@oneliners);
          }
        }
      }
      if (uc($oneliner{'sign'}) =~/Y/) {
        push (@oneliners,$info{'id'}."|".$oneliner{'blah'});
      } else {
        push (@oneliners,"|".$oneliner{'blah'});
      }
      lockfile("$config{'home'}$config{'text'}/oneliner");
      open (onlout,">$config{'home'}$config{'text'}/oneliner");
      foreach $oneliner(@oneliners) {
        chomp ($oneliner);
        print onlout $oneliner."\n";
      }
      close (onlout);
      unlockfile("$config{'home'}$config{'text'}/oneliner");
    }
    undef %oneliner;
    writeline("\n");
  }
  $inteleconf=1
  }
}
return 1;
