#!/usr/bin/env perl
use warnings;
use strict;

# Helpers
sub parse {
   my ($in) = @_;
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
               if($tmp4[0] ne 'int') {$valid = 0; }
               push(@functionDef, split(/\s+/,$tmp4[0]));
            }
         } else {
            my @tmp4 = split(/\s+/,$tmp2[0]);
            if($tmp4[0] ne 'int') {$valid = 0; }
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

sub makeTest {
   my ($functionList, $write_name) = @_;
   foreach(@$functionList) {
      my @arr = @$_;
      print "Testing function: ";
      foreach(@arr) {
         print("'$_' ");
      }
      print "\n";
   }

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

# Script Start
our $in;
our $out;
if($#ARGV + 1 != 2) {
   die "Err: Correct form: Harness.pl [input file] [output file name]";
}
$in = shift(@ARGV);
$out = shift(@ARGV);

if($in !~ m{.java$}) {
   die "Input: '$in' must be a .java file";
}
if($out !~ m{.java$}) {
   die "Output: '$out' must end with '.java'";
}
print "Input File: $in\nOutput File Name: $out\n\n";

my $functionList = parse($in);
makeTest($functionList, $out);
print "\nComplete\n";
