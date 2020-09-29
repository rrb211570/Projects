#!/usr/bin/env perl
use warnings;
use strict;

# Helpers
sub parse {
   my ($in, $commandType) = @_;
   open(my $infile, $in) or die "Could not open file: '$in'";
   my @in_name = split(/.java$/, $in); # class name

   my @functionList;
   while(<$infile>) {
      if(/\s*\S+\s+\S+\s*\([\s*\S+\s+\S+\s*,]*\s*\S+\s+\S+\s*\)\s*\{/) {
         my @functionDef;
         push(@functionDef, (/^.*\s+(\S+)\s+(\S+)\s*\(/g));
         my @tmp = split(/\s*\(\s*/,$_);
         my @tmp2 = split(/\s*\)/,$tmp[1]);
         my $valid = 1;
         if($tmp2[0] =~ /\,/){
            my @tmp3 = split(/\s*\,\s*/,$tmp2[0]);
            foreach(@tmp3) {
               my @tmp4 = split(/\s+/,$_);
               if($tmp4[0] ne 'int' && $commandType == 0) {$valid = 0; } # toggle
               push(@functionDef, split(/\s+/,$tmp4[0]));
            }
         } else {
            my @tmp4 = split(/\s+/,$tmp2[0]);
            if($tmp4[0] ne 'int' && $commandType == 0) {$valid = 0; } # toggle
            push(@functionDef,$tmp4[0]);
         }
         if($valid == 1) {
            push(@functionList,\@functionDef);
         }
      }
   }
   close($infile) or die "Could not close";
   return \@functionList;
}

sub validateMap {
   my ($map) = @_;
   open(my $infile, $map) or die "Could not open file: '$map'";

   # parse
   my $state = 0;
   my $head;
   my @in;
   my $args = 0;
   my $tmpArgs;
   while(<$infile>) {
      if($state == 0) {
         if(/^\s*(\S+)\s*$/) {
            $head = $1;
            $state = 1;
         } else {
            die "Invalid format in mapping file:\n\n$_\n\n";
         }
      } elsif($state == 1) {
         if(/^\s*\( \s*( (\S+\s*\,\s*)* (\s*\S+) )\s* \)\s*$/x) {
            my $input_line = $1;
            # split up into array;
            if($input_line =~ /^.*\,.*$/){
               @in = split(/\s*\,\s*/,$input_line);
               $tmpArgs = @in;
            } else {
               $tmpArgs = 1;
            }
            if($args==0) {
               $args = $tmpArgs;
            } else {
               if($args != $tmpArgs) {
                  die "Inconsistent #input_args in mapping file:\n\n$_\n\n";
               }
            }
         } else {
            die "Invalid format in mapping file:\n\n$_\n\n";
         }
         @in = ();
         $state = 2;
      } elsif($state == 2) {
         if(/^\s*(\S+)\s*$/) {
            $state = 1;
         } else {
            die "Invalid output in mapping file:\n\n$_\n\n";
         }
      }
   }
   return $head;
}

sub parseMap {
   my ($map) = @_;
   open(my $infile, $map) or die "Could not open file: '$map'";

   # parse
   my @mapFunctionList;
   my $state = 0;
   my $head;
   my @in;
   my $out;
   while(<$infile>) {
      if($state == 0) {
         if(/^\s*(\S+)\s*$/) {
            $head = $1;
            $state = 1;
         } else {
            die "Invalid format in mapping file:\n\n$_\n\n";
         }
      } elsif($state == 1) {
         if(/^s*;\s*/) {
            $state = 0;
         } elsif(/^\s*\( \s*( (\S+\s*\,\s*)* (\s*\S+) )\s* \)\s*$/x) {
            my $input_line = $1;
            # split up into array;
            if($input_line =~ /^.*\,.*$/){
               @in = split(/\s*\,\s*/,$input_line);
            } else {
               /^\s*(\S+)\s*$/;
               push(@in, $1);
            }
            $state = 2;
         } else {
            die "Invalid format in mapping file1:\n\n$_\n\n";
         }
      } elsif($state == 2) {
         if(/^\s*(\S+)\s*$/) {
            my @line;
            $out = $1;
            push(@line,$head);
            foreach(@in) {
               push(@line, $_);
            }
            push(@line, $out);
            push(@mapFunctionList,\@line);
            $state = 1;
            @in = ();
         } else {
            die "Invalid format in mapping file2:\n\n$_\n\n";
         }
      }
   }
   return \@mapFunctionList;
}

sub makeStress {
   my ($functionList, $write_name) = @_;
   open(my $outfile, ">$write_name") or die "Could not open file";
   my @write_class = split(/.java/,$write_name);

   # populate .java stress test
   print $outfile "//Integer Stress Test\n\n";
   print $outfile "class $write_class[0] {\n";
   print $outfile "   public static void main(String[] args){\n";
   foreach(@$functionList) {
      my @arr = @$_;
      print $outfile "      for(int i=Integer.MIN_VALUE; i<=Integer.MAX_VALUE; ++i){\n";
      print $outfile "         $arr[1](";
      foreach my $i(2..(($#arr)-1)) {
         print $outfile "i, ";
      }
      print $outfile "i);\n      }\n";
   }
   print $outfile "   }\n}";
   close($outfile) or die "Could not close";
}

sub makeMap {
   my ($function, $mapCases, $write_name) = @_;
   open(my $outfile, ">$write_name") or die "Could not open file";
   my @write_class = split(/.java/,$write_name);

   # populate .java stress test
   print $outfile "//IO Mapping\n";
   print $outfile "import java.util.*;\n\n";
   print $outfile "class $write_class[0] {\n";
   print $outfile "   public static void main(String[] args){\n";
   print $outfile "      Test testFile = new Test();";
   print $outfile "      int passed = 0;\n";
   my $tests = @$mapCases;
   print $outfile "      int tests = $tests;\n";
   print $outfile "      HashMap<int[], Integer> mp = new HashMap<int[], Integer>();\n";
   my $argLength;
   foreach(@$mapCases) {
      my @arr = @$_;
      print $outfile "      mp.put(new int[]{";
      $argLength = ($#arr)-2;
      foreach my $i(1..(($#arr)-2)) {
         print $outfile "$arr[$i], ";
      }
      my $tmp = $#arr - 1;
      my $tmpLast = $tmp + 1;
      print $outfile "$arr[$tmp]},  $arr[$tmpLast]);\n";
   }
   print $outfile "\n      for(int[] in_case : mp.keySet()){\n";
   print $outfile "         if(testFile.$function(";
   foreach my $i(0 .. ($argLength-1)) {
      print $outfile "in_case[$i], ";
   }
   my $outputArg = $argLength+1;
   print $outfile "in_case[$argLength]) == mp.get(in_case) ) passed++;\n";
   print $outfile "      }\n";
   print $outfile "\n      System.out.println(\"$write_class[0]: \"+passed+\"/\"+tests+\" tests passed\.\");\n";
   print $outfile "   }\n}";
   close($outfile) or die "Could not close";
}

sub printFunction {
   my ($functionList) = @_;
   foreach(@$functionList) {
      my @arr = @$_;
      print "Testing function: ";
      foreach(@arr) {
         print("'$_' ");
      }
      print "\n";
   }
}

sub getHeaders {
   my ($functionList) = @_;
   my @heads;
   foreach(@$functionList) {
      my @arr = @$_;
      push(@heads, $arr[1]);
   }
   return \@heads;
}

sub getTestHeaders {
   my ($functionList) = @_;
   my @heads;
   foreach(@$functionList) {
      my @arr = @$_;
      push(@heads, $arr[0]);
   }
   return \@heads;
}

# Script Start
our $in;
our $out;
our $map;
my $commandType = -1;

# Decide what test to run
if($#ARGV + 1 == 2) {
   $commandType = 0; # Stress Test
}
if($#ARGV + 1 == 3) {
   $commandType = 1; # IO Mapping Test
}
if($commandType == -1) {
   die "\nErr: Correct form:\n\nInt Stress Test: Harness.pl [input file] [output file name]\nIO Mapping Test: Harness.pl [input file] [output file name] [mapping file]\n\nFlags: '-v' : verbose\n";
}
$in = shift(@ARGV);
$out = shift(@ARGV);

# validate correct input formats, valid Java input file
if($in !~ m{.java$}) {
   die "Input: '$in' must be a .java file";
}
my $ret = system("javac $in");
if($ret != 0) {
   die "javac failed on input: $in\n";
}
if($out !~ m{.java$}) {
   die "Output: '$out' must end with '.java'";
}
print "\n Input File: $in\nOutput File: $out\n";
if($commandType == 1) {
   $map = shift(@ARGV);
   if($map !~ m{.txt$}) {
      die "\nInput: '$map' must be a .txt file\n";
   }
   print " IO Mapping: $map\n";
}
print "\n";

# process
my $functionList = parse($in, $commandType);
# printFunction($functionList);

if($commandType == 0){
   makeStress($functionList, $out);
}
if($commandType == 1){
   # ------ make sure IO mapping corresponds with function IO
   my $function = validateMap($map);
   my $mapCases = parseMap($map);
   # printFunction($mapCases);
   my $headers = getHeaders($functionList);
   my %hash = @$headers;
   if(!exists($hash{$function})) {
      die "Error: function '$_' does not exist in $in\n";
   }

   makeMap($function, $mapCases, $out);
}
print "Complete\n";
