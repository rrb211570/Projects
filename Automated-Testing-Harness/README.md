# Perl-based Test Harness (Currently only supports int param stress test)

Command: Harness.pl [input file] [output file]

Parses 'input file' for functions with solely integer parameters, and creates/replaces a file named by 'output file'. Both file names must have '.java' extension.

The output file is populated w/ Java code that stress tests the appropriate functions:
Iterating over each function, w/ (Integer.MIN_VALUE to Integer.MAX_VALUE) being assigned to each int parameter. 

Essentially finds runtime errors associated with code behavior.
