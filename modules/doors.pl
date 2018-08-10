#!/usr/bin/perl

sub setupdoors {

  unless (-d "$config{'doors'}/nodes/$info{'node'}") {
    mkdir ("$config{'doors'}/nodes/$info{'node'}");
  }

  lockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo$doornode.def");
  open (out,">$config{'doors'}/nodes/$info{'node'}/dorinfo$doornode.def");
    print out "$config{'systemname'}\r\n$config{'sysop'}\r\n\r\nCOM1:\r\n19200 BAUD,N,8,1\r\n1\r\n$info{'handle'}\r\n\r\n$info{'location'}\r\n$info{'ANSI'}\r\n110\r\n110\r\n1\r\n";
  close (out);
  unlockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo$doornode.def");

  lockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo1.def");
  open (out,">$config{'doors'}/nodes/$info{'node'}/dorinfo1.def");
    print out "$config{'systemname'}\r\n$config{'sysop'}\r\n\r\nCOM1:\r\n19200 BAUD,N,8,1\r\n1\r\n$info{'handle'}\r\n\r\n$info{'location'}\r\n$info{'ANSI'}\r\n110\r\n110\r\n1\r\n";
  close (out);

  unlockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo1.def");
  lockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo1.def");
  open (out,">$config{'doors'}/nodes/$info{'node'}/door.sys");
        print out "COM1:\r\n38400\r\n8\r\n1\r\n38400\r\nY\r\nY\r\nY\r\nY\r\n$info{'handle'}\r\n$info{'location'}\r\n$info{'phonenumber'}\r\n$info{'phonenumber'}\r\nPASSWORD\r\n110\r\n1456\r\n03/14/88\r\n7560\r\n126\r\nGR\r\n23\r\nY\r\n1,2,3,4,5,6,7\r\n7\r\n12/31/99\r\n1\r\nY\r\n0\r\n0\r\n0\r\n999999\r\n10/22/88\r\nG:\\GAP\\MAIN\r\nG:\\GAP\\GEN\r\n$config{'sysop'}\r\n$config{'sysop'}\r\n00:05\r\nY\r\n$info{'ansi'}\r\nY\r\n14\r\n10\r\n07/07/90\r\n14:32\r\n07:30\r\n6\r\n3\r\n23456\r\n76329\r\n$config{'systemname'}\r\n10\r\n10283\r\n";
  close (out);
  unlockfile("$config{'doors'}/nodes/$info{'node'}/dorinfo1.def");

  lockfile("$config{'doors'}/nodes/$info{'node'}/fusiondoor");
  open (out,">$config{'doors'}/nodes/$info{'node'}/fusiondoor");
   print out "username=$info{'handle'}\nservername=$info{'systemname'}\nnode=$info{'node'}\nsecurity=$userinfo{'security'}\nansi=$info{'ansi'}\n";
  close (out);
  unlockfile("$config{'doors'}/nodes/$info{'node'}/fusiondoor");
}
return 1;
