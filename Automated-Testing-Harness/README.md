# Perl-based Test Harness 
(Currently supports int-param stress test and int-param IO mapping)

# Int-param stress test
Command: Perl Harness.pl [input file] [output file]

Parses (input file).java for any int-param functions, and creates/replaces a file named by (output file).java.  
Ex. int-param function: "type function(int, int, int, int){ //code }

(output file).java : Programmatically created file that calls the int-param functions,
                     in a for-loop, w/ Integer.MIN_VALUE to Integer.MAX_VALUE being given to each parameter.
                     
Purpose: discovers run-time errors;

# Int-param IO mapping

Command: Perl Harness.pl [input file] [output file] [mapping file]

mapping file looks like:
-----------------------------
function //function name
(0, 1, 33, 5) //in
12 //out
(1, 44, 55, 6) //in
5 //out
---------------------------

(output file).java : Programmatically created file that creates a HashMap containing
                     the input-output mapping in (mapping file).txt, and runs a for-loop
                     counting how many test cases pass.
                     
                     Prints out: "(output file): a/b tests passed."

A mapping file can only contain test cases for one function.
