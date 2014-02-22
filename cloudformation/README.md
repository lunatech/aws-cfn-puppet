CFN template files quickly become unmamageably huge so I have
split apart the files into separate pieces to make them easier to
reuse and work with.

A `.template` file is simply a JSON fragment that will be included
wholesale into a large document.

The Makefile uses the C preprocessor to consume a single top-level
template (which may then include other tempaltes) and generates single
JSON file that Amazon's CFN tools will understand.

There are two phases to template preprocessing:

1. Running each template through the C preprocessor (which 
   processes includes, defines, etc.). The `CPP` and
   `CPPFLAGS` can be used to select and pass options to
   the preprocessor. These default to `cpp` and no options
   by default.
   
2. Stripping the final file of any unwanted artifacts inserted
   by the preprocessor and (optionally) running a JSON formatter
   on the final output. The `JSONLINT` and `JSONLINTFLAGS`
   variables can be used to select and pass options to the JSON
   formatter. These default to `cat` (i.e. no formatting). A 
   JSON formatter should read from standard input and write to
   standard output.
   
The final template will be produced as `aws-cfn-puppet.json` in
this directory.
   

