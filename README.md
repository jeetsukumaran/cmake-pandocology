# PANDOCOLOGY

"Pandocology" is a [CMake](http://www.cmake.org/) module that allows you to generate documents using [pandoc](http://johnmacfarlane.net/pandoc/).
It is very much modeled after [UseLATEX](http://www.cmake.org/Wiki/CMakeUserUseLATEX), and is meant to make the process of going from source to final product as easy as possible, so you can focus on writing instead of compiling.


## Requirements

-   Pandoc
-   LaTeX
-   latexmk


## Installation

Simply place the file "`pandocology.cmake`" in a place where CMake can find it, i.e., somewhere on your CMake module path.

For example, given a typical CMake project organized as:

~~~
project/
    cmake/Modules/
    src/
~~~

you might place this file "`pandocology.cmake` in "`project/cmake/Modules`", and then add a line like the following either in the top-level "`CMakeLists.txt`" or any other "`CMakeLists.txt`" processed before the commands provided by "Pandocology" are needed:

~~~
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules")
~~~

In my own case, I have cloned this entire repository as a submodule of my project module:
~~~
$ cd cmake/Modules
$ git submodule add https://github.com/jeetsukumaran/cmake-pandocology.git
~~~

And I added the following line to my top-level "`CMakeLists.txt`":

~~~
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/cmake-pandocology")
~~~

Once you have added the file to your project working tree, and made sure that CMake knows how to find it by updating the CMake module path, then as with any other CMake module, you need to source or include it in the "`CmakeLists.txt`" file in which you are going to use it:

~~~
INCLUDE(pandocology)
~~~

## Basic Usage

The primary command offered by "Pandocology" is "`add_document()`".

This command takes, at a mininum, two arguments: a *target name*, which specifies the output file (and, by inspection of the extension, the output file format), and at least one source file specifed by the "`SOURCES`" argument.
So, for example, if you had a Markdown format input file (say, "`opus.md`") that you wanted to convert to Rich Text Format, then the following is a minimal "`CMakeLists.txt`" to do that.

~~~
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/cmake-pandocology")
INCLUDE(pandocology)

add_document(
    opus.rtf
    SOURCES opus.md
)
~~~

Once the project is built, the result "`opus.rtf`" will end up in the "`product`" subdirectory of the build directory.
You can change the output directory by using the "`PRODUCT_DIRECTORY`" argument:
~~~
add_document(
    opus.rtf
    SOURCES opus.md
    PRODUCT_DIRECTORY opus_output_directory
)
~~~

## Passing Directives to "`pandoc`"

You have access to the full complexity of the Pandoc compiler through the "`PANDOC_DIRECTIVES`" argument, which will pass everything to the underlying "`pandoc`" program. So, for example, to generate a PDF with some custom options:

~~~
add_document(
    opus.pdf
    SOURCES opus.md
    PANDOC_DIRECTIVES -t latex
                      --smart
                      --self-contained
                      --toc
                      --listings
)
~~~

## Including Static Resources

In many cases your inputs are going to be more than just the primary source document: images, CSS stylesheets, BibTeX bibliography database files, stylesheets, templates etc.
All these secondary files or inputs that are not the primary input to the "`pandoc`" program but are required to compile the main document are known as "*resources*".

These resources can be specified on a file-by-file basis using the "`RESOURCE_FILES`" argument and on a directory-by-directory basis using the "`RESOURCE_DIRS`" argument (note that all paths are relative to the current source directory):

~~~
add_document(
    opus.pdf
    SOURCES opus.md
    RESOURCE_FILES references.bib custom.template.latex journal.csl
    RESOURCE_DIRS  figures/ maps/
    PANDOC_DIRECTIVES -t latex
                      --smart
                      --self-contained
                      --toc
                      --listings
                      --template     custom.template.latex
                      --filter       pandoc-citeproc
                      --csl          journal.csl
                      --bibliography references.bib
)
~~~

**IMPORTANT NOTE:** When adding resources on a directory-bases using the `RESOURCE_DIRS` argument, all the resources that are in that directory *at the time* `cmake ..` is run are added as dependencies. The CMake system does not provide a way to monitor directories for changes, only files. Thus, if you add (or remove) files from any of the directories specified by the `RESOURCE_DIRS` argument, you will have to run `cmake ..` again to make sure that the build system adds (or removes) these files from the build specifications.

## Including Content After the Reference Section

One quirk of "`pandoc`" is that the bibliography/reference section is necessarily the last part of the main document body: you cannot (easily and organically) have any sections, such as an appendix, after the reference section.
The work-around is to create these post-reference sections as a separate document, independentally process them using "`pandoc`", and then use the "`--include-after-body`" directive to include them in the main document.

You can support this workflow using Pandocology as follows:
~~~
add_document(
    appendices.tex
    SOURCES              appendices.md
    RESOURCE_DIRS        appendix-figs
    PANDOC_DIRECTIVES    -t latex
    NO_EXPORT_PRODUCT
    )

add_document(
    opus.pdf
    SOURCES             opus.md
    RESOURCE_FILES      references.bib custom.template.latex journal.csl
    RESOURCE_DIRS       figures/ maps/
    PANDOC_DIRECTIVES   -t             latex
                        --smart
                        --listings
                        --template     custom.template.latex
                        --filter       pandoc-citeproc
                        --csl          journal.csl
                        --bibliography references.bib
                        --include-after-body=appendices.tex
    DEPENDS             appendices.tex
    )
~~~

The first instruction asks Pandocology to build the LaTeX document "`appendices.tex`" from the (Markdown) source, "`appendices.md`", making to sure include the files in the subdirectory, "`appendix-figs`".
The argument "`NO_EXPORT_PRODUCT`" tells Pandocology that while we want the file "`appendices.tex`" built, but *not* exported to the final output directory (i.e., "`product`" or as specified by the "`PRODUCT_DIRECTORY`" argument).
Pandocology makes sure that all build products are built in the current binary source directory so that they are available to other builds within the project, and only copies the final result to the output/product directory.
By specifying "`NO_EXPORT_PRODUCT`", we are suppressing the final step, and thus we have the file, "`appendices.tex`" available in the source directory to be pulled in by the build for "`opus.tex`", but not exported to the final product directory where it will just be noise.

The second instruction builds the primary output that we are interested in, i.e., "`opus.pdf`", from the (Markdown) source "`opus.md`".
Note how we specify the "`--include-after-body=appendices.tex`" argument to "`pandoc`", to make sure the Pandoc compiler pulls in the generated TeX file into the main document.
In addition, we also list "`appendices.tex`" as a dependency using the "`DEPENDS`" argument.
This results in Pandocology informing the CMake build system that "`appendices.tex`" will be used in the building of "`opus.pdf`".
This is how we make sure that built or generated resources are available in the right place at the right time (as opposed to the "`RESOURCE_FILES`" and "`RESOURCE_DIRS`" arguments, which make sure that *static* resources get to the right places at the right time).
Of course, as before, we make sure to specify all the static resources that this document needs (e.g. the bibliography file, the templates, the images in the "`figures/`" and "`maps/`" subdirectories).

## Creating an Archive Bundle for Submission

With some output formats that are themselves source formats requiring further processing (e.g., LaTeX), you may want to create an self-contained archive that includes not only the output document, but also additional resources that the output document may need for further processing.
You can do this by specifying the "`EXPORT_ARCHIVE`" flag, which will create a compressed archive of the final file *as well as* all the static resource files, the static resource directories, *and* the generated resource dependencies:

~~~
add_document(
    appendices.tex
    SOURCES              appendices.md
    RESOURCE_DIRS        appendix-figs
    PANDOC_DIRECTIVES    -t latex
    NO_EXPORT_PRODUCT
    )

add_document(
    opus.tex
    SOURCES             opus.md
    RESOURCE_FILES      references.bib custom.template.latex journal.csl
    RESOURCE_DIRS       figures/ maps/
    PANDOC_DIRECTIVES   -t             latex
                        --smart
                        --listings
                        --template     custom.template.latex
                        --filter       pandoc-citeproc
                        --csl          journal.csl
                        --bibliography references.bib
                        --include-after-body=appendices.tex
    DEPENDS             appendices.tex
    EXPORT_ARCHIVE
    )
~~~

In the above case, once run, the output directory will not only have the primary Pandoc-compilation output, "`opus.tex`", but also a BZIP-compressed and TAR'd archive, "`opus.tbz`", which includes the file "`opus.tex`" *and* all the resources specified by the "`RESOURCE_FILES`" and "`RESOURCE_DIRS`" arguments, as well as the  resources specified in by the "`DEPENDS`" argument.

If you want *just* the archive (which include the primary product, i.e., "`opus.tex`" in the example above), and not the primary file to be created in the output directory, then specify "`EXPORT_ARCHIVE`" and "`NO_EXPORT_PRODUCT`" together. The former creates the archive and the latter suppresses the creation of a separate (and perhaps, for your purposes, redundant) output.
~~~
add_document(
    opus.tex
    SOURCES             opus.md
    RESOURCE_FILES      references.bib custom.template.latex journal.csl
    RESOURCE_DIRS       figures/ maps/
    PANDOC_DIRECTIVES   -t             latex
                        --smart
                        --listings
                        --template     custom.template.latex
                        --filter       pandoc-citeproc
                        --csl          journal.csl
                        --bibliography references.bib
                        --include-after-body=appendices.tex
    DEPENDS             appendices.tex
    NO_EXPORT_PRODUCT
    EXPORT_ARCHIVE
    )
~~~

## Generating Both a PDF and the TeX, and Creating an Archive Bundle for Submission

Many journals require that you submit both a PDF as well as a TeX source, and, in the latter, may require that all source files needed to TeX the source are also included.
The way to do this using Pandocology is to:

1. Specify that the primary output is LaTeX that you want an archive exported that bundles the LaTeX file plus all the resources and dependencies by using the "`EXPORT_ARCHIVE`" argument.
1. Specify that you want the primary output to be post-processed into a PDF using the "`EXPORT_PDF`" argument.
1. Suppress the creation of the primary LaTeX output (since it is already in the archive bundle) by using the "`NO_EXPORT_PRODUCT`" argument.


~~~
add_document(
    appendices.tex
    SOURCES              appendices.md
    RESOURCE_DIRS        appendix-figs
    PANDOC_DIRECTIVES    -t latex
    NO_EXPORT_PRODUCT
    )

add_document(
    opus.tex
    SOURCES              opus.md
    RESOURCE_FILES       references.bib custom.template.latex journal.csl
    RESOURCE_DIRS        figs
    PANDOC_DIRECTIVES    -t             latex
                        --smart
                        --listings
                        --template     custom.template.latex
                        --filter       pandoc-citeproc
                        --csl          journal.csl
                        --bibliography references.bib
                        --include-after-body=appendices.tex
    DEPENDS             appendices.tex
    NO_EXPORT_PRODUCT
    EXPORT_ARCHIVE
    EXPORT_PDF
    )
~~~

If the above is run, the output directory will have two files: "`opus.pdf`" and "`opus.tbz`".
The former is the PDF of the document while the latter is the LaTeX file plus all resources needed to generate the PDF.

## Working with Pure TeX and LaTeX Source Files: Using Pandocology without using Pandoc

The Pandocology module provides some build functionality that might be desirable even if you are not actually using or want to use Pandoc.
For example, the resource management feature, the ability to bundle all source and resource files into an archive, the ability to specify an output directory, and so on.
If you have a a TeX or a LaTeX project, and you want to generate the final PDF's without using Pandoc but still want to use Pandocology to manage the build process so that you have access to these extra features of Pandocology, you can specify the ``DIRECT_TEX_TO_PDF`` flag, which can be used in conjunction with any other options described previously (though, of course, some options such as ``PANDOC_DIRECTIVES`` make no sense in this context and will be ignored):

~~~
add_document(
    opus.pdf
    SOURCES              opus.tex
    RESOURCE_FILES       opus.bib figures.tex sysbio.bst
    RESOURCE_DIRS        figs
    DIRECT_TEX_TO_PDF
    EXPORT_ARCHIVE
    )
~~~

As can be seen, all resources and resource directories (as well as dependencies) are specified as before.

For convenience (mnemonic as much as operational), you can call the function ``add_tex_document()`` instead:

~~~
add_tex_document(
    opus.pdf
    SOURCES              opus.tex
    RESOURCE_FILES       opus.bib figures.tex sysbio.bst
    RESOURCE_DIRS        figs
    EXPORT_ARCHIVE
    )
~~~

In either case, using the direct-tex-to-PDF feature requires that:

-   There must be only one source (though an arbitrary number of additional sources included in the main source can be specfied using the "``RESOURCE_FILES``" and "``RESOURCE_DIRS`` arguments).
-   The source name (i.e., "``opus.tex``" in the above examples) *must* have a "``.tex``" or "``.latex``" extension, and, of course, must be in TeX or LaTeX format.
-   The target name (i.e., "``opus.pdf``" in the above examples) *must* have a "``.pdf``" extension, and match the source name exactly except for the extension.

