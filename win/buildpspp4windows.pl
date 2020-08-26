#!/usr/bin/perl
#==============================================================================
# buildpspp4windows - a script for generating a PSPP MSWindows installer.
#   Copyright (C) 2010-2016 Harry Thijssen
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#==============================================================================
#
# This script is intended to generate a MSWindows setup of PSPP.
# The preconditions:
# - the folders /usr/i686-mingw32/sys-root/mingw  
#               /usr/x64_64-mingw32/sys-root/mingw have 777 rights 
# - all preconditions for mingw32-configuring, mingw32-make and NSIS are set
# - iconv must be installed and needs a reinstallation after any toolchain upgrade  ???
# if a gitbuild is made, you also need to install:  git, libtool and gperf 
#
use strict;
use warnings;
use diagnostics;
use Cwd 'abs_path';
use File::Copy;
use File::Basename;
use Fcntl ':mode';
use POSIX qw(strftime);


my $psppGenericName = "pspp-master";
my $UploadTextExtension = "TestBuild";    
$UploadTextExtension = "ForTestingOnly";
my $UploadFileExtension = "";   
if ($UploadTextExtension ne "TestBuild") {
   $UploadFileExtension = "-".$UploadTextExtension;   
}   

my $keep = 0;
my $refresh = 0;
my $help = 0;
my $patch = 0;
my $argc = 0;
my $TestBuild = 0;
my $GitBuild = 0;
my $Check = 0;
my $file;
my @files;
my $MyScript = abs_path($0);
my $answer = "";

my $psppRepoVersion = "";
my $repo_version = "";
my $psppSubversion = "";
my $psppVersion = "";
my $binaryversion = "";
my $gitbranch = "";
my $build_request = "latest"; # default "latest"     
#   $build_request = "20160801030501"; # default "latest"    
my $w32w64 = "";
my $Debug = ""; 
my $MingwPrefix = "";
my $WindowsPlatform = "";
my $build_number = "latest"; # default "latest"
my $UploadDir = "";
my $MingwDir = "";    # mingw32 directory
my $psppRepoVersionWinName = "";
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
my $permissions;
my $KindIndicator;

#ProcCommandLineHandling();

my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime time;
my $StrDateVersion = sprintf "%4d%02d%02d", $year+1900,$mon+1,$mday;
my $NumDateVersion = sprintf "20.%02d.%02d.%02d", $year-100,$mon+1,$mday;
my $DisplDateVersion = sprintf "%4d-%02d-%02d", $year+1900,$mon+1,$mday;

my $BaseDir = "$ENV{HOME}";
my $WebDir   = "$BaseDir/webdisk/pspp";
my $BaseWorkDir = "$BaseDir/$psppGenericName-$StrDateVersion";
my $BaseUploadDir = "$BaseWorkDir/Upload";
my $FinalDir = "$BaseWorkDir/pspp";

ProcCommandLineHandling();

printf "Generating $psppGenericName-%4d%02d%02d\n", $year+1900,$mon+1,$mday;

ProcGetBuildInfo();

$mday      = substr $build_number, 6, 2;
$mon       = substr $build_number, 4, 2;
$year      = substr $build_number, 0, 4;

$StrDateVersion  = sprintf "%4d%02d%02d", $year,$mon,$mday;
$NumDateVersion  = sprintf "%4d.%02d.%02d", $year,$mon,$mday;
$DisplDateVersion  = sprintf "%4d-%02d-%02d", $year,$mon,$mday;
$UploadDir = "$BaseUploadDir/$DisplDateVersion-$UploadTextExtension";
mkdir "$BaseWorkDir";
mkdir "$BaseUploadDir";# create a tempdir for the results.
mkdir "$UploadDir";# create a tempdir for the results.
mkdir "$UploadDir/used-in-build";
mkdir "$UploadDir/used-in-build/inc";
mkdir "$UploadDir/used-in-build/nsis";
mkdir "$UploadDir/DebugVersion";
print "UploadDir:      $UploadDir\n";
print "build_number:   $build_number\n";
print "psppRepoVersionWinName: $psppRepoVersionWinName\n";
print "git_branch:     $gitbranch\n";
print "psppVersion:    $psppVersion\n";
print "repo_version:    $repo_version\n";

sleep(10.01);

ProcCollectFiles();
ProcGeneratePSPP("w32","Debug");
ProcGeneratePSPP("w32","Normal");
$MingwDir = "/usr/x86_64-w64-mingw32/sys-root/mingw";
if (-d $MingwDir){
  ProcGeneratePSPP("w64","Debug");
  ProcGeneratePSPP("w64","Normal");
}
ProcUploading();

#  ==================== sub routines ============================

sub ProcGetBuildInfo
{
  system("wget -O/tmp/latest.txt http://pspp.benpfaff.org/~blp/$psppGenericName/$build_request/source/index.html") == 0 or die "Wget failed: $!";
  open FILE, "</tmp/latest.txt";
  my @lines = <FILE>;
  for (@lines) {
    if ($_ =~ /version</) {
        $psppVersion  = "pspp-".substr $_, 24, -11;    
    }
    if ($_ =~ /build_number/) {
        $build_number = substr $_, 29, -11;
    }
    if ($_ =~ /git_branch/){
        $gitbranch = substr $_, 27, -11;
    }
    if ($_ =~ /repo_version/){
        $repo_version = substr $_, 29, -11;
    }
  }
  if ($GitBuild) {
    $psppVersion  = "pspp-g".substr "$StrDateVersion", 3, 6;  
  }
#  unlink("/tmp/latest.txt");
  $psppRepoVersion = "pspp-".$repo_version;
#  $psppRepoVersionWinName = $psppRepoVersion;
#  $psppRepoVersionWinName =~ s/\.//g;
  $psppRepoVersionWinName = "pspp";
  
}

sub ProcCommandLineHandling
{
  print "******************************************\n";
  print "* start ".localtime()."  $MyScript \n";
  print "******************************************\n";
  if ($#ARGV >= 0) {
    if (substr $ARGV[0], 0,2 eq "20") {
      $build_request = $ARGV[0];
    }
  }

  foreach my $arg (@ARGV) {
   $help = $help || ("$arg" eq '-h' || "$arg" eq '--help');         
   $refresh = $refresh || ($arg eq "-r" || $arg eq "--refresh");
   $keep = $keep || ($arg eq "-k" || $arg eq "--keep");
   $patch = $patch || ($arg eq "-p" || $arg eq "--patch");
   $TestBuild = $TestBuild || ($arg eq "-t" || $arg eq "--testbuild");
   $GitBuild = $GitBuild || ($arg eq "-g" || $arg eq "--gitbuild");
   $Check = $Check || ($arg eq "-c" || $arg eq "--check");
   unless ('-' eq (substr $arg, 1, 1)) {
      $help      = $help      || ($arg =~ m/h/i);
      $refresh   = $refresh   || ($arg =~ m/r/i);
      $keep      = $keep      || ($arg =~ m/k/i);
      $patch     = $patch     || ($arg =~ m/p/i);
      $TestBuild = $TestBuild || ($arg =~ m/t/i);
      $GitBuild  = $GitBuild  || ($arg =~ m/g/i);
      $Check     = $Check     || ($arg =~ m/c/i);
    }
  }
  if ($TestBuild) { 
    $UploadTextExtension = "ForTestingOnly";
    $UploadFileExtension = "-".$UploadTextExtension;   
  }

  if ($help)  {
      print "Syntax:  $0 [build_number] [options]";
      print "Possible parameters:\n";
      print "build_number\n";
      print " -b or --build   : build a new installer (default)\n";
      print " -h or --help    : help (this screen)\n";
      print " -k or --keep    : keep the workdirectory and its content\n";
      print " -p or --patch   : use patches from BaseDir/pspp-patches\n";
      print " -r or --refresh : removes files first and start a fresh generate\n";
      print " -g or --gitbuild : build from git\n";
      print " -c or --check  : run make check\n";
      print " -o or --output : compile without surpression of standard output, this gives an ugly black screen!\n";
      exit;
  }
}

sub ProcCollectFiles
{
  unless (-f  "$UploadDir/used-in-build/$psppGenericName-$StrDateVersion-src.tar.gz") {
    system("wget -O$BaseUploadDir/pspp-user-manual.pdf  http://pspp.benpfaff.org/~blp/$psppGenericName/$build_number/source/user-manual/pspp.pdf") == 0 or die "Wget pspp.def failed: $!";
    system("wget -O$BaseUploadDir/pspp-user-manual.html http://pspp.benpfaff.org/~blp/$psppGenericName/$build_number/source/user-manual/pspp.html") == 0 or die "Wget pspp.html failed: $!";
    if (!$GitBuild) {  
      system("wget -O$UploadDir/used-in-build/$psppGenericName-$StrDateVersion-src.tar.gz http://pspp.benpfaff.org/~blp/$psppGenericName/$build_number/source/$psppVersion.tar.gz") == 0 or die "Wget failed getting the latest tarball. Most likely their was an error in generating it today. Error $!"; 
    }  
  }

  copy ("$WebDir/used-in-build/nsis/MUI_EXTRAPAGES.nsh", "$UploadDir/used-in-build/nsis") or die "copy MUI_EXTRAPAGES,nsh to uploaddir failed: $!";
  copy ("$WebDir/used-in-build/nsis/AdvUninstLog.nsh", "$UploadDir/used-in-build/nsis") or die "copy AdvUninstLog.nsh to uploaddir failed: $!";
  copy ("$WebDir/used-in-build/inc/mswindows_icons.tar.gz", "$UploadDir/used-in-build/inc") or die "copy mswindows_icons.tar.gz to currentdir failed: $!";
  copy ("$WebDir/used-in-build/inc/startPSPP.bat", "$UploadDir/used-in-build/inc") or die "copy startPSPP.bat to uploaddir failed: $!";
  copy ("$WebDir/used-in-build/inc/DebugPSPP.bat", "$UploadDir/used-in-build/inc") or die "copy DebugPSPP.bat to finaldir failed: $!";
#  copy ("$WebDir/used-in-build/inc/settings.ini", "$UploadDir/used-in-build/inc") or die "copy settings.ini to uploaddir failed: $!";
  # collect missing files not provided by mingw pacakages
  copy ("/usr/share/icons/hicolor/index.theme", "$UploadDir/used-in-build/index.theme") or die "copy index.theme to uploaddir failed: $!";
}


sub ProcGeneratePSPP 
{
  $w32w64 = "$_[0]";   
  $Debug  = "$_[1]";   

  $MingwPrefix = "i686";
  $WindowsPlatform = "32bits";
  my  $ProgramFiles = '$Programfiles32';
  $KindIndicator = "2"; 
  if ($w32w64 eq "w64") {             
    $MingwPrefix = "x86_64"; 
    $ProgramFiles = '$Programfiles64';
    $WindowsPlatform = "64bits";
    $KindIndicator = "4"; 
  }                                           
  system("echo ProcGeneratePSPP: WindowsPlatform: $WindowsPlatform Debug: $Debug | mutt -s 'Start ProcGeneratePSPP' 'pspp4windows\@gmail.com'") == 0 or die "ready mail not send!";  
     
  $MingwDir = "/usr/$MingwPrefix-w64-mingw32/sys-root/mingw";
  unless(-d $MingwDir){die "$MingwDir not found. Install the required Mingw toolchain using, for example with 'Cross-compiling-PSPP.ymp', first";}

  if (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat("$MingwDir/bin")) {
        $permissions = sprintf "%04o", S_IMODE($mode);
        print "File permissions of $MingwDir/bin: $permissions\n";
     if ($permissions != 777) {
       print "Press any key to continue";
       #The <STDIN> is the way to read keyboard input
       $answer = <STDIN>;
       system("sudo chmod -R 777 $MingwDir") ==0 or die "chmod $MingwDir failed";
     } else {
       print "$MingwDir/bin is already writable!\n"
     }  
  } else {
    print "Please specify an EXISTING file!\n";
  }

  sub ProcCollectVersionDependedFiles
  {
    chdir "$BaseWorkDir";
  
    if ("$Debug" ne 'Debug') {
      system("cat $WebDir/used-in-build/nsis/pspp.nsi | sed '/DebugPSPP/d' > $UploadDir/used-in-build/nsis/pspp.nsi") == 0 or die "create pspp.nsi without debug failed: $!"; 
    } else {
      copy ("$WebDir/used-in-build/nsis/pspp.nsi", "$UploadDir/used-in-build/nsis") or die  "copy pspp.nsi to uploaddir failed: $!";
    }
  
    chdir "$MingwDir/lib/pkgconfig";
    open BP, ">/tmp/PKGConfig.txt";
    print BP "Packages used for the $WindowsPlatform build:\n\n";
    my @files;
    my $file;
    my $version;
    @files = <*.pc>;
    foreach $file (@files) {
      open FILE, "<$file";
      $version = "x";
      my @lines = <FILE>;
      for (@lines) {
        if ($_ =~ /Version/) {
          $version  = $_;
        }
      } 
      print BP substr(substr($file,0,-3)."                              ",0,22).substr($version,9);
    }
    chdir "$MingwDir/share/pkgconfig";
    @files = <*.pc>;
    foreach $file (@files) {
      open FILE, "<$file";
      $version = "x";
      my @lines = <FILE>;
      for (@lines) {
        if ($_ =~ /Version/) {
          $version  = $_;
        }
      } 
      print BP substr(substr($file,0,-3)."                              ",0,22).substr($version,9);
    }
    print BP "\n";
    close BP;
 
 ###########   
    open RM3, ">/tmp/read.me3";
    print RM3 "\n\n";
    print RM3 "Source info\n";
    print RM3 "\n";
    print RM3 "BuildNumber:    $build_number\n";
    print RM3 "GitBranch:      $gitbranch\n";
    print RM3 "PSPPVersion:    $psppVersion\n";  
    print RM3 "\n";
    close RM3; 
##########    
    if ("$Debug" ne 'Debug') {
      chdir "$UploadDir"
    } else {
      chdir "$UploadDir/DebugVersion"
    }
    system("cat /tmp/read.me3 > Build-Properties-$WindowsPlatform.txt") == 0 or die "readme.txt failed: $!";
    system("cat /tmp/PKGConfig.txt >> Build-Properties-$WindowsPlatform.txt") == 0 or die "readme.txt failed: $!";
    
    system("rpm -q -a  mingw32-cross-nsis | sed s/mingw32-cross-nsis-// | xargs --no-run-if-empty echo 'nsis                 ' >> Build-Properties-$WindowsPlatform.txt" ) == 0 or die "rpm for nsis  wrong: $!";
#    system("echo 'iconv                 1.15' >> Build-Properties-$WindowsPlatform.txt") == 0 or die "echo  failed: $!";
#    if (-f "$MingwDir/bin/psql.exe")   {
#      system("wine $MingwDir/bin/psql.exe -V >> Build-Properties-$WindowsPlatform.txt") == 0 or die "psql.exe not found: $!";
#    }
    system("echo '' >> Build-Properties-$WindowsPlatform.txt") == 0 or die "echo  failed: $!";
    system("cat $WebDir/BuildVersion.txt >> Build-Properties-$WindowsPlatform.txt") == 0 or die "cat  failed: $!";
    system("echo '' >> Build-Properties-$WindowsPlatform.txt") == 0 or die "echo  failed: $!"; 
    system("echo 'Build platform info:' >> Build-Properties-$WindowsPlatform.txt") == 0 or die "echo  failed: $!"; 
    system("echo '' >> Build-Properties-$WindowsPlatform.txt") == 0 or die "echo  failed: $!"; 
    system("cat /etc/os-release >> Build-Properties-$WindowsPlatform.txt") == 0 or die "readme.txt failed: $!";
    
    chdir "$BaseWorkDir";
  } 
  
  sub ProcGlibSchemasCompiled
  {
    if (! (-f "$MingwDir/share/glib-2.0/schemas/gschemas.compiled")) { ; #check schemas are compiled  
      system("wine $MingwDir/bin/glib-compile-schemas.exe $MingwDir/share/glib-2.0/schemas") == 0 or die "glib-compile-schemas aborted: $!";
    }
  }
    
  ProcGlibSchemasCompiled();
  ProcCollectVersionDependedFiles();
  ProcCreatingFinalSource();

  print "******************************************\n";
  print "* Preparing for installer generation     *\n";
  print "******************************************\n";
  
  #getting the icons and creating the directory icons
  mkdir "$MingwDir/share/pspp";
  system("tar -xvf $UploadDir/used-in-build/inc/mswindows_icons.tar.gz -C $MingwDir/share/pspp") == 0 or die "tar failed: $!";    
  ProcCreatingResourceInfo(); 
  ProcMake();

  ProcCreatingInstallTree();

  print "******************************************\n";
  print "* Preparing for NSIS                     *\n";
  print "******************************************\n";
  chdir "$BaseWorkDir"; 
  open FH, ">/tmp/NSISParameters.nsh";
  print FH "!Define Version $DisplDateVersion\n";
  print FH "!Define IconDir $BaseWorkDir\n";
  print FH "!Define SourceDir $BaseWorkDir/pspp/*\n";
  if ("$Debug" eq 'Debug') {
    print FH "!Define OutExe $UploadDir/DebugVersion/$psppRepoVersionWinName-$StrDateVersion-daily-$WindowsPlatform$UploadFileExtension-setup.Debug\n";
  } else {
    print FH "!Define OutExe $UploadDir/$psppRepoVersionWinName-$StrDateVersion-daily-$WindowsPlatform$UploadFileExtension-setup.exe\n";
  }
  print FH "!Define WebDir $WebDir\n";
  print FH "!Define ProgramFiles $ProgramFiles\n";
  print FH "!Define MUI_EXTRAPAGES $UploadDir/used-in-build/nsis/MUI_EXTRAPAGES.nsh\n";
  print FH "!Define AdvUninstLog $UploadDir/used-in-build/nsis/AdvUninstLog.nsh\n";
  print FH "!Define repo_version $repo_version\n";
  close FH; 
  
  system("cat $WebDir/used-in-build/PackageInfo1.txt >  /tmp/PackageInfo.txt") == 0 or die "packageinfo failed: $!";
  system("cat $WebDir/used-in-build/readme.txt       >> /tmp/PackageInfo.txt") == 0 or die "packageinfo failed: $!";
  system("cat $WebDir/used-in-build/PackageInfo3.txt >> /tmp/PackageInfo.txt") == 0 or die "packageinfo failed: $!";
  system("cat /tmp/read.me3            >> /tmp/PackageInfo.txt") == 0 or die "packageinfo failed: $!";

  system("makensis $UploadDir/used-in-build/nsis/pspp.nsi") == 0 or die "makensis failed : $!"; 
  
  my $mypackagename;
  if ("$Debug" eq 'Debug') {
    $mypackagename = "$psppRepoVersionWinName-$StrDateVersion-daily-$WindowsPlatform$UploadFileExtension-setup.Debug";
    chdir "$UploadDir/DebugVersion"; 
    system("md5sum $mypackagename  > $mypackagename.md5") == 0 or die "md5sum failed : $!";    
    system("sha1sum $mypackagename > $mypackagename.sha1") == 0 or die "sha1sum failed : $!";
  } else {
    $mypackagename = "$psppRepoVersionWinName-$StrDateVersion-daily-$WindowsPlatform$UploadFileExtension-setup";
    chdir "$UploadDir"; 
    system("md5sum $mypackagename.exe  > $mypackagename.md5") == 0 or die "md5sum failed : $!";    
    system("sha1sum $mypackagename.exe > $mypackagename.sha1") == 0 or die "sha1sum failed : $!";
  }  
  chdir "$BaseWorkDir"; 

#******************* procedures ***************************************************8
  sub ProcCreatingFinalSource
  {
    print "******************************************\n";
    print "* Creating final source           ********\n";
    print "******************************************\n";
    chdir "$BaseWorkDir"; 
    if (!$GitBuild) {  
      system("tar -xvf $UploadDir/used-in-build/$psppGenericName-$StrDateVersion-src.tar.gz") == 0 or die "tar failed: $!";
    } else {
      chdir "..";
      if (!-d "gnulib") {
        system("git clone git://git.savannah.gnu.org/gnulib.git")  == 0 or die "git gnulib failed!";
        chdir "gnulib"; 
        system("git checkout baef0a4b9433d00e59c586b9eaad67d8461d7324")  == 0 or die "git commit failed!";
      }  
      chdir "$BaseWorkDir";  
      if (!-d "$psppVersion") {
        system("git clone -b master git://git.savannah.gnu.org/pspp.git $psppVersion")  == 0 or die "git pspp!";
        chdir "$psppVersion"; 
        # git libtool gperf makeinfo (>= 5.2) postgresql-devel on build computer
        system("make -f Smake GNULIB=../../gnulib")  == 0 or die "make -f Smake failed!";  
      
        if (-d "$WebDir/pre-tarball-patches") {
          opendir(DIR, "$WebDir/pre-tarball-patches");
          @files = grep(/\.patch$/,readdir(DIR));
          closedir(DIR);
          foreach $file (@files) {
            system("patch -p 1 --verbose < $WebDir/pre-tarball-patches/$file")  == 0 or die "patch $file failed: $!";
            if (! -d "$UploadDir/used-in-build/pspp-patches") {
              mkdir "$UploadDir/used-in-build/pspp-patches";
            }
            copy ("$WebDir/pre-tarball-patches/$file",  "$UploadDir/used-in-build/pspp-patches/$file") or die "copy $file to basedir failed: $!";
          }
        } 
        chdir "$BaseWorkDir";
        system("tar -zcvf $UploadDir/used-in-build/$psppVersion.tar.gz $psppVersion/*")  == 0 or die "creating tarball failed!"; 
      }
    }

    chdir "$BaseWorkDir/$psppVersion";

    # overruling parts of the sources  
    if ($build_request eq "latest") {
#      system("wget -Opo/nl.po    http://translationproject.org/PO-files/nl/$psppRepoVersion$psppSubversion.nl.po") == 0 or die "Wget failed: $!";
#      copy ("$WebDir/$psppRepoVersion.nl.po", "po/nl.po") or die "copy $WebDir/$psppRepoVersion.nl.po to po  failed: $!";
#      copy ("$WebDir/$psppRepoVersion.nl.po", "$UploadDir/used-in-build/nl.po") or die "copy $WebDir/$psppRepoVersion.nl.po to basedir failed: $!";
#      system("wget -Opo/ru.po    http://translationproject.org/PO-files/ru/$psppRepoVersion$psppSubversion.ru.po") == 0 or die "Wget failed: $!";
    }

    if ($patch) {
       # create a list of patch files and patch the source with them 
      if (-d "$WebDir/pspp-patches") {
        opendir(DIR, "$WebDir/pspp-patches");
        @files = grep(/\.opt-patch$/,readdir(DIR));
        closedir(DIR);
        foreach $file (@files) {
          if (! -d "$UploadDir/used-in-build/pspp-patches") {
            mkdir "$UploadDir/used-in-build/pspp-patches";
          }
          system("patch -p 1 --verbose < $WebDir/pspp-patches/$file")  == 0 or die "patch $file failed: $!";
          copy ("$WebDir/pspp-patches/$file",  "$UploadDir/used-in-build/pspp-patches/$file") or die "copy $file to basedir failed: $!";
        }
      }
    }

    # create a list of mandatory patch files and patch the source with them 
    if (-d "$WebDir/pspp-patches") {
      opendir(DIR, "$WebDir/pspp-patches");
      @files = grep(/\.patch$/,readdir(DIR));
      closedir(DIR);
      foreach $file (@files) {
        if (! -d "$UploadDir/used-in-build/pspp-patches") {
          mkdir "$UploadDir/used-in-build/pspp-patches";
        }
        system("patch -p 1 --verbose < $WebDir/pspp-patches/$file")  == 0 or die "patch $file failed: $!";
        copy ("$WebDir/pspp-patches/$file", "$UploadDir/used-in-build/pspp-patches/$file") or die "copy $file to basedir failed: $!";
      }  
    }
  }



  sub ProcCreatingResourceInfo  
  {
    my $dayNumber = POSIX::strftime("%j", gmtime time);
    my $YearLastDigit = substr $build_number, 3, 1;

    print "******************************************\n";
    print "* Creating resource info          ********\n";
    print "******************************************\n";
    my $myrepo_version = $repo_version;
    $myrepo_version =~ s/\./,/g;
    open FH, ">/tmp/pspp.rc";
    print FH "PSPP-SPLASH ICON \"$MingwDir/share/pspp/icons/pspp.ico\"\n";
    print FH "1 VERSIONINFO\n";
#   
#    my $count = ($repo_version =~ tr/"."//); 
#    if ($count < 3) {
#      print FH "FILEVERSION     $myrepo_version,$YearLastDigit$dayNumber$KindIndicator\n";
#    } else {
#      print FH "FILEVERSION     $myrepo_version\n";
#    }
    print FH "FILEVERSION     $YearLastDigit$dayNumber$KindIndicator\n";
    print FH "BEGIN\n";
    print FH "  BLOCK \"StringFileInfo\"\n";
    print FH "  BEGIN\n";
    print FH "    BLOCK \"080904E4\"\n";
    print FH "    BEGIN\n";
    print FH "      VALUE \"CompanyName\",     \"http://sourceforge.net/projects/pspp4windows\"\n";
    print FH "      VALUE \"FileDescription\", \"PSPPIRE  (PSPP+GUI)\"\n";
    print FH "      VALUE \"FileVersion\", \"\"\n";
    print FH "      VALUE \"InternalName\", \"$binaryversion\"\n";
    print FH "      VALUE \"LegalCopyright\", \"(c)Free Software Foundation, Inc.  GPLv3\"\n";
    print FH "      VALUE \"OriginalFilename\", \"PSPPIRE.exe\"\n";
    print FH "      VALUE \"ProductName\", \"$psppRepoVersion  $gitbranch\"\n";
    print FH "      VALUE \"ProductVersion\", \"$psppVersion  $WindowsPlatform\"\n";
    print FH "    END\n";
    print FH "  END\n";
    print FH "  BLOCK \"VarFileInfo\"\n";
    print FH "  BEGIN\n";
    print FH "    VALUE \"Translation\", 0x809, 1252\n";
    print FH "  END\n"; 
    print FH "END\n";
    close FH; 
    system("$MingwPrefix-w64-mingw32-windres /tmp/pspp.rc -O coff -o /tmp/pspp.res") == 0  or die "system 'windres'  failed: $?";
  }

  sub ProcMake
  {
    print "******************************************\n";
    print "* Clean & Configuring     $Debug             ********\n";
    print "******************************************\n";
    $ENV{PG_CONFIG} = "$MingwDir/bin"; # set the PG_CONFIG so the config proces can find the postgresql PG_CONFIG file
    if (-f  "Makefile") {
      print "******************************************\n";
      print "* Make distclean                  ********\n";
      print "******************************************\n";
      system("ming$w32w64-make distclean") == 0  or die "system 'Ming$w32w64-make distclean'  failed: $?";
      if (-f  "ming$w32w64-config.cache") {
        system("rm ming$w32w64-config.cache") == 0  or die "system 'rm ming$w32w64-config.cache'  failed: $?";
      }     
    }
    if ("$Debug" ne 'Debug') {
      system("ming$w32w64-configure  --enable-relocatable PSPPIRE_LDFLAGS='-Wl,-subsystem,windows,/tmp/pspp.res' --with-libpq") == 0  or die "system 'Ming$w32w64-configure'  failed: $?";
      print "******************************************\n";
      print "* Make                            ********\n";
      print "******************************************\n";
      system("ming$w32w64-make") == 0  or die "system 'Ming$w32w64-make'  failed: $?";
    } else {
      system("ming$w32w64-configure  --enable-relocatable PSPPIRE_LDFLAGS='/tmp/pspp.res' --with-libpq") == 0  or die "system 'Ming$w32w64-configure'  failed: $?";
      print "******************************************\n";
      print "* Make                            ********\n";
      print "******************************************\n";
      system("ming$w32w64-make CFLAGS='-ggdb -o0'") == 0  or die "system 'Ming$w32w64-make'  failed: $?";
    }
    print "******************************************\n";
    print "* Make install                    ********\n";
    if (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat("$MingwDir/share/info")) {
          $permissions = sprintf "%04o", S_IMODE($mode);
          print "File permissions of $MingwDir/bin: $permissions\n"; 
       if ($permissions != 777) {
         print "Press any key to continue";
         #The <STDIN> is the way to read keyboard input
        $answer = <STDIN>;
        system("sudo chmod -R 777 $MingwDir") ==0 or die "chmod failed: sudo chmod -R 777 $MingwDir ";
       }  
    } else {
          print "Please specify an EXISTING file!\n";
    }
    print "******************************************\n";
    system("ming$w32w64-make install") == 0  or die "system 'Ming$w32w64-make install'  failed: $?";
    
    system("ming$w32w64-make html") == 0  or die "system 'Ming$w32w64-make html'  failed: $?";
    system("ming$w32w64-make install-html") == 0  or die "system 'Ming$w32w64-make install-html'  failed: $?";    
    
    if (($Check) && ("$Debug" eq 'Debug')) {  
#    if (($Check) && ($w32w64 eq "w64")) { 
      print "******************************************\n";
      print "* Make check                      ********\n";
      print "******************************************\n";
      $ENV{'PATH'} = $ENV{'PATH'}.":$MingwDir/bin";
      my $answer = "";
      system("ming$w32w64-make RUNNER=wine check") == 0  or $answer = "problem";
      my $ChecksFailed=`grep unexpectedly tests/testsuite.log | sed  "s/failed unexpectedly.//g" | tr --delete '\n'`;
      my $ChecksSkipped=`grep "tests were skipped." | sed  "s/tests were skipped.//g"  | tr --delete '\n'` ;
      my $NumberOfChecks=`grep "tests were run," tests/testsuite.log | sed "s/tests were run,//g" | sed "s/ERROR://g" | tr --delete '\n'`;
      my $SuccessfulTests=$NumberOfChecks-$ChecksFailed;
      my $PreviousSuccessfulTests = 0;
      if (!-d "$BaseDir/PSPPGenWin") {
        mkdir "$BaseDir/PSPPGenWin";
      } else {
        $PreviousSuccessfulTests=`grep "SuccessFul tests:" $BaseDir/PSPPGenWin/Previous.txt | sed  "s/SuccessFul tests://g"`;
      }
      printf "SuccessFul tests:$SuccessfulTests\n";
      
      if ($NumberOfChecks > 1000) {
        open(FH, ">$BaseDir/PSPPGenWin/Previous.txt") or die "Couldn't open: $!";
        print FH "Total Number Tests: $NumberOfChecks\n";
        print FH "Failed Tests:       $ChecksFailed\n";
        print FH "SuccessFul tests:   $PreviousSuccessfulTests\n";
        print FH "Skipped tests:      $ChecksSkipped\n";
        close FH; 
      }
      printf "SuccessFul tests:$SuccessfulTests\n";
      open(FH, ">$WebDir/PSPPGenWin/Previous.txt") or die "Couldn't open: $!";
      print FH "SuccessFul tests:$SuccessfulTests\n";
      close FH; 
      system("echo Check is ready: SuccessFul tests:$SuccessfulTests  Previous SuccessfulTests: $PreviousSuccessfulTests | mutt -s 'Check is ready' 'pspp4windows\@gmail.com'") == 0 or die "ready mail not send!";  
      if ($SuccessfulTests > $SuccessfulTests) {
        printf "SuccessFul tests:$SuccessfulTests,  Previous SuccessfulTests: $PreviousSuccessfulTests \n";
        print "Please type any key: ";
        #The <STDIN> is the way to read keyboard input
        $answer = <STDIN>;
      }
      
      if ($answer eq "problem")  {
          print "Please type any key: ";
          #The <STDIN> is the way to read keyboard input
          $answer = <STDIN>;
      }
    }  
  }
  
  sub ProcCreatingInstallTree
  {
    print "******************************************\n";
    print "* Creating install directory             *\n";
    print "******************************************\n"; 

    if (-f "$BaseWorkDir/pspp.tar") {
       unlink("$BaseWorkDir/pspp.tar");
    }
    if (-d "$FinalDir") {
         system("rm -r  /$FinalDir") == 0 or die "rm -r /$FinalDir failed: $!";
    }
    chdir "$MingwDir";
      
    system("tar -cf $BaseWorkDir/pspp.tar bin/*pspp*.exe bin/gspawn-win??-helper.exe  bin/*.dll") == 0 or die "Tar failed: $!";  
    system("tar -rf $BaseWorkDir/pspp.tar etc/*") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/pspp/*") == 0 or die "Tar failed: $!";  
    system("tar -rf $BaseWorkDir/pspp.tar share/themes/*") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/gtksourceview-3.0/styles/*") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/gtksourceview-3.0/language-specs/*.rng") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/gtksourceview-3.0/language-specs/*.dtd") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/gtksourceview-3.0/language-specs/def.lang") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/icons/hicolor/*") == 0 or die "Tar failed: $!";
    system("tar -rf $BaseWorkDir/pspp.tar share/icons/Adwaita/16x16/* share/icons/Adwaita/2?x2?/*") == 0 or die "Tar failed: $!";
    system("tar -rf $BaseWorkDir/pspp.tar share/icons/Adwaita/index.theme") == 0 or die "Tar failed: $!";
    system("tar -rf $BaseWorkDir/pspp.tar share/doc/pspp/pspp.html/*") == 0 or die "Tar failed: $!";    
    system("tar -rf $BaseWorkDir/pspp.tar share/glib-2.0/schemas/*") == 0 or die "Tar failed: $!";   
    system("tar -rf $BaseWorkDir/pspp.tar share/locale/ca/*    share/locale/cs/*    share/locale/de/*    share/locale/el/*    share/locale/es/*") == 0 or die "Tar failed: $!";  
    system("tar -rf $BaseWorkDir/pspp.tar share/locale/en_GB/* share/locale/fr/*    share/locale/gl/*    share/locale/hu/*    share/locale/ja/*    share/locale/lt/*") == 0 or die "Tar failed: $!"; 
    system("tar -rf $BaseWorkDir/pspp.tar share/locale/nl/*    share/locale/pt_BR/* share/locale/pl/*    share/locale/zh_CN/*") == 0 or die "Tar failed: $!";  
    system("tar -rf $BaseWorkDir/pspp.tar share/locale/ru/*    share/locale/sl/*    share/locale/uk/*") == 0 or die "Tar failed: $!";  
    if ("$Debug" eq 'Debug') {
      system("tar -rf $BaseWorkDir/pspp.tar bin/gdb.exe") == 0 or die "tar failed: $!";  
    }  
    
    mkdir "/$FinalDir";            
    system("tar -xf $BaseWorkDir/pspp.tar -C /$FinalDir") == 0 or die "Tar -x failed: $!"; 
    unlink("$BaseWorkDir/pspp.tar");
     if ("$Debug" eq 'Debug') {
      system("cp -R $BaseWorkDir/$psppVersion/src /$FinalDir") == 0 or die "all failed: $!";  
      system("cp -R $BaseWorkDir/$psppVersion/gl  /$FinalDir") == 0 or die "all failed: $!"; 
      copy ("$UploadDir/used-in-build/inc/DebugPSPP.bat", "$FinalDir/bin") or die "copy DebugPSPP.bat to finaldir failed: $!";
    }     
     # copy files not provided by mingw packages on the right place    
    copy ("$UploadDir/used-in-build/index.theme", "/$FinalDir/share/icons/hicolor") or die "copy index.theme to finaldir failed: $!";
    copy ("/$FinalDir/share/icons/Adwaita/22x22/status/image-missing.png", "/$FinalDir/share/icons/image-missing.png") or die "copy image-missing.png to finaldir failed: $!";
   
    # copying/converting all the required files to a temporary directory 
    system("unix2dos -n $BaseWorkDir/$psppVersion/README   $FinalDir/share/README.txt")  == 0 or die "Copy/unix2dos failed: $!";
    system("unix2dos -n -f $BaseWorkDir/$psppVersion/NEWS  $FinalDir/share/NEWS.txt")    == 0 or die "Copy/unix2dos failed: $!";
    system("unix2dos -n $BaseWorkDir/$psppVersion/COPYING  $FinalDir/share/COPYING.txt") == 0 or die "Copy/unix2dos failed: $!";
    system("unix2dos -n $BaseWorkDir/$psppVersion/AUTHORS  $FinalDir/share/AUTHORS.txt") == 0 or die "Copy/unix2dos failed: $!";
    system("unix2dos -n $BaseWorkDir/$psppVersion/THANKS   $FinalDir/share/THANKS.txt")  == 0 or die "Copy/unix2dos failed: $!"; 

    opendir(DIR, "$BaseWorkDir/$psppVersion/examples");
    @files = grep(/\.sps$/,readdir(DIR));
    closedir(DIR);
    foreach $file (@files) { 
      system("unix2dos -n  $BaseWorkDir/$psppVersion/examples/$file $FinalDir/share/pspp/examples/$file") == 0 or die "unix2dos failed: $!"; 
    } 
  
    copy ("$BaseUploadDir/pspp-user-manual.pdf", "$FinalDir/share/doc/pspp/user-manual.pdf") or die "copy pspp-master.pdf to basedir failed: $!"; 
        
    chdir "$FinalDir";   
    if (-d "$WebDir/mingw-patches") {
      opendir(DIR, "$WebDir/mingw-patches");
      @files = grep(/\.patch$/,readdir(DIR));
      closedir(DIR);
      foreach $file (@files) {
        if (! -d "$UploadDir/used-in-build/mingw-patches"){
          mkdir "$UploadDir/used-in-build/mingw-patches";
        }
        system("patch -p 1 --verbose < $WebDir/mingw-patches/$file")  == 0 or die "patch $file failed: $!";
        copy ("$WebDir/mingw-patches/$file",  "$UploadDir/used-in-build/mingw-patches/$file") or die "copy $file to basedir failed: $!";
      }
    }
    
    chdir "$MingwDir";
        
    copy ("$UploadDir/used-in-build/inc/startPSPP.bat", "$FinalDir/bin") or die "copy startPSPP.bat to finaldir failed: $!";
  }
 

#======================== end of ProcGeneratePSPP ====================================
}



sub ProcUploading 
{
  print "******************************************\n";
  print "* Uploading  ".localtime()."              \n";
  print "******************************************\n";
  chdir "$BaseUploadDir";
 
  copy ("$WebDir/used-in-build/readme.txt", "$UploadDir") or die "copy readme.txt to uploaddir failed: $!"; 
  system("cat /tmp/read.me3   >> $UploadDir/readme.txt") == 0 or die "readme.txt failed: $!";
  copy ("$WebDir/used-in-build/readme-debug.txt", "$UploadDir/DebugVersion/readme.txt") or die "copy readme-debug.txt to uploaddir/debugversion failed: $!"; 
  copy ("$FinalDir/share/NEWS.txt", "$BaseUploadDir/NEWS.txt") or die "Copy news.txt failed: $!";
  copy ("$BaseUploadDir/NEWS.txt",  "$UploadDir/NEWS.txt") or die "copy news.txt to uploaddir failed: $!";
  #if ($UploadTextExtension eq "ForTestingOnly") {
  #  copy ("$WebDir/used-in-build/readme-ForTestingOnly.txt", "$UploadDir/readme-ForTestingOnly.txt") or die "copy readme-ForTestingOnly.txt to uploaddir failed: $!"; 
  #}
  system("cat /tmp/read.me3   >> $UploadDir/DebugVersion/readme.txt") == 0 or die "debug/readme.txt failed: $!";
#  copy ("$MyScript", "$UploadDir/used-in-build/".basename($MyScript)) or die "copy to basedir failed: $!"; 
  print "Gebruikte routine $MyScript controleeer waarom dity niet goed werkt";  
  copy ("/home/harry/webdisk/pspp/buildpspp4windows.pl", "$UploadDir/used-in-build/buildpspp4windows.pl") or die "copy to basedir failed: $!";
  print "******************************************\n";
  print "* Rsync to sourceforge ".localtime()."    \n";
  print "******************************************\n";
  system("echo PSPP4Windows is ready to upload.| mutt -s 'PSPP4Windows is generated' 'pspp4windows\@gmail.com'") == 0 or die "ready mail not send!";  
  print "Press any key to continue";
  #The <STDIN> is the way to read keyboard input
  $answer = <STDIN>;
  print "* Rsync to sourceforge start ".localtime()."    \n";
  my $MySourceforge = 'pspp4windows,pspp4windows@frs.sourceforge.net:/home/frs/project/pspp4windows';
  system("rsync -avP -e ssh * $MySourceforge") == 0 or
        system("rsync -avP -e ssh * $MySourceforge") == 0 or
              system("rsync -avP -e ssh * $MySourceforge") == 0 or
                    system("rsync -avP -e ssh * $MySourceforge") == 0 or
                          system("rsync -avP -e ssh * $MySourceforge") == 0 or
                                system("rsync -avP -e ssh * $MySourceforge") == 0 or
                                      system("rsync -avP -e ssh * $MySourceforge") == 0 or
                                            system("rsync -avP -e ssh * $MySourceforge") == 0 or
                                                  system("rsync -avP -e ssh * $MySourceforge") == 0 or die "rsync failed: $!";
  chdir "$BaseDir";
  unless ($keep) {
    print "******************************************\n";
    print "* remove working directory ".localtime()."\n";
    print "******************************************\n";
    system("rm -r  $BaseWorkDir") == 0 or die "rm -r failed: $!";
  }
  print "******************************************\n";
  print "* finished ".localtime()."\n";
  print "******************************************\n";
}

