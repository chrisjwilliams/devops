# Developer Guide
devops is a perl based Object Orirentated project.

## Coding Conventions
- Every class is in a .pm file of the same name
  - except where the class is considered internal to another class and is not used directly by any other class
- Class names shall all be PsscalCase
- variable names shall all be lower case with _ to represent word seperation
     
## Repository Structure
devops -
       |- Externals                     Perl module dependencies external to this project
       |- Installation                  Scripts to set up devops on the host system
       |- DevOps                        The perl core app modules source code
            |- test                     The unit tests for core modules
            |- Configuration            Configuration file parsing modules
            |- Cli                      The Command Line Interface to the core modules
            |- TestUtils                Module specific reusable testing utilities
            |- VersionControl           Plugin modules for the various revision control systems projects use

## Unit Tests
- Every class shall have a unit test in the test subdirectory with the name
   test_ClassName.pm. This will implement a test class.
- each test should be a method of the test class. The list of test methods should be returned by the tests() method of
  this class.
- tests are executed by running the test.pl script found in each test sub directory.
