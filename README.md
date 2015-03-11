
# PANDOCOLOGY

"Pandocology" is a [CMake](http://www.cmake.org/) module that allows you to generate documents using [pandoc](http://johnmacfarlane.net/pandoc/).
It is very much modeled after [UseLATEX](http://www.cmake.org/Wiki/CMakeUserUseLATEX), and is meant to make the process of going from source to final product as easy as possible, so you can focus on writing instead of compiling.

## Installation

Simply place the file "`pandocology.cmake`" in a place where CMake can find it, i.e., some where on your CMake module path.

For example, given a typical CMake project organized as:

~~~
project/
    cmake/Modules/
    src/
~~~

you would place this file "`pandocology.cmake` in "`project/cmake/Modules`".

Alternatively, if you wish to place the file elsewhere, you have to make sure that you update the CMake module path by placing a line like the following in your "`CMakeLists.txt`":

~~~
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "path/to/pandocology/dir")
~~~

For example, in my own case, I have cloned this entire repository as a submodule of my project module:
