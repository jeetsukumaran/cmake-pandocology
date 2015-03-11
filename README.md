# PANDOCOLOGY

"Pandocology" is a [CMake](http://www.cmake.org/) module that allows you to generate documents using [pandoc](http://johnmacfarlane.net/pandoc/).
It is very much modeled after [UseLATEX](http://www.cmake.org/Wiki/CMakeUserUseLATEX), and is meant to make the process of going from source to final product as easy as possible, so you can focus on writing instead of compiling.

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

## Usage

The primary command offered by "Pandocology" is "`add_pandoc_document()`".

This command takes, at a mininum, two arguments: a *target name*, which specifies the output file (and, by inspection of the extension, the output file format), and at least one source file specifed by the "`SOURCES`" argument.
So, for example, if you had a Markdown format input file (say, "`opus.md`") that you wanted to convert to Rich Text Format, then the following is a minimal "`CMakeLists.txt`" to do that.

~~~
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/cmake-pandocology")
INCLUDE(pandocology)

add_pandoc_document(
    opus.rtf
    SOURCES opus.md
)
~~~

You have access to the full complexity of the Pandoc compiler through the "`PANDOC_DIRECTIVES`" argument, which will pass everything to the underlying "`pandoc`" program. So, for example, to generate a PDF with some custom options:

~~~
add_pandoc_document(
    opus.pdf
    SOURCES opus.md
    PANDOC_DIRECTIVES -t latex
                      --smart
                      --self-contained
                      --toc
                      --listings
)
~~~

