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
