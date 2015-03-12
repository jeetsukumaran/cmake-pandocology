################################################################################
##
##  Provide Pandoc compilation support for the CMake build system
##
##  Version: 0.0.1
##  Author: Jeet Sukumatan (jeetsukumaran@gmail.com)
##
##  Copyright 2015 Jeet Sukumaran.
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License along
##  with this program. If not, see <http://www.gnu.org/licenses/>.
##
###############################################################################

include(CMakeParseArguments)

if(NOT EXISTS ${PANDOC_EXECUTABLE})
    # find_program(PANDOC_EXECUTABLE NAMES pandoc)
    find_program(PANDOC_EXECUTABLE pandoc)
    mark_as_advanced(PANDOC_EXECUTABLE)
    if(NOT EXISTS ${PANDOC_EXECUTABLE})
        message(FATAL_ERROR "Pandoc not found. Install Pandoc (http://johnmacfarlane.net/pandoc/) or set cache variable PANDOC_EXECUTABLE.")
        return()
    endif()
endif()

###############################################################################
# Based on UseLATEX:LATEX_COPY_INPUT_FILE
# Author: Kenneth Moreland <kmorel@sandia.gov>
# Copyright 2004 Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000, there is a non-exclusive
# license for use of this work by or on behalf of the
# U.S. Government. Redistribution and use in source and binary forms, with
# or without modification, are permitted provided that this Notice and any
# statement of authorship are reproduced on all copies.
function(pandocology_add_input_file source_path dest_dir dest_filelist_var)
    set(dest_filelist)
    get_filename_component(filename ${source_path} NAME)
    get_filename_component(absolute_dest_path ${dest_dir}/${filename} ABSOLUTE)
    list(APPEND dest_filelist ${absolute_dest_path})
    ADD_CUSTOM_COMMAND(
        OUTPUT ${absolute_dest_path}
        COMMAND ${CMAKE_COMMAND} -E copy ${source_path} ${absolute_dest_path}
        DEPENDS ${source_path}
        )
    set(${dest_filelist_var} ${${dest_filelist_var}} ${dest_filelist} PARENT_SCOPE)
endfunction()
###############################################################################

function(pandocology_get_file_stemname varname filename)
    SET(result)
    GET_FILENAME_COMPONENT(name ${filename} NAME)
    STRING(REGEX REPLACE "\\.[^.]*\$" "" result "${name}")
    SET(${varname} "${result}" PARENT_SCOPE)
endfunction()

function(pandocology_add_input_dir source_dir dest_parent_dir dest_filelist_var)
    set(dest_filelist)
    get_filename_component(dir_name ${source_dir} NAME)
    get_filename_component(absolute_dest_dir ${dest_parent_dir}/${dir_name} ABSOLUTE)
    add_custom_command(
        OUTPUT ${absolute_dest_dir}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${absolute_dest_dir}
        DEPENDS ${source_dir}
        )
    file(GLOB source_files "${source_dir}/*")
    foreach(source_file ${source_files})
        # get_filename_component(absolute_source_path ${CMAKE_CURRENT_SOURCE_DIR}/${source_file} ABSOLUTE)
        pandocology_add_input_file(${source_file} ${absolute_dest_dir} dest_filelist)
    endforeach()
    set(${dest_filelist_var} ${${dest_filelist_var}} ${dest_filelist} PARENT_SCOPE)
endfunction()

function(add_to_make_clean filepath)
    get_directory_property(make_clean_files ADDITIONAL_MAKE_CLEAN_FILES)
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${make_clean_files};${filepath}")
endfunction()

function(disable_insource_build)
    IF ( CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR AND NOT MSVC_IDE )
        MESSAGE(FATAL_ERROR "The build directory must be different from the main project source "
"directory. Please create a directory such as '${CMAKE_SOURCE_DIR}/build', "
"and run CMake from there, passing the path to this source directory as "
"the path argument. E.g.:
    $ cd ${CMAKE_SOURCE_DIR}
    $ mkdir build
    $ cd build
    $ cmake .. && make && sudo make install
This process created the file `CMakeCache.txt' and the directory `CMakeFiles'.
Please delete them:
    $ rm -r CMakeFiles/ CmakeCache.txt
")
    ENDIF()
endfunction()

# This builds a document
#
# Usage:
#
#
#     INCLUDE(pandocology)
#
#     add_pandoc_document(
#         figures.tex
#         SOURCES              figures.md
#         RESOURCE_DIRS        figs
#         PANDOC_DIRECTIVES    -t latex
#         NO_EXPORT_PRODUCT
#         )
#
#     add_pandoc_document(
#         archipelago-model.pdf
#         SOURCES              archipelago-model.md
#         RESOURCE_FILES       archipelago-model.bib systbiol.template.latex systematic-biology.csl
#         RESOURCE_DIRS        figs
#         PANDOC_DIRECTIVES    -t             latex
#                             --smart
#                             --template     systbiol.template.latex
#                             --filter       pandoc-citeproc
#                             --csl          systematic-biology.csl
#                             --bibliography archipelago-model.bib
#                             --include-after-body=figures.tex
#         DEPENDS             figures.tex
#         EXPORT_ARCHIVE
#         )
#
function(add_pandoc_document target_name)
    set(options          EXPORT_ARCHIVE NO_EXPORT_PRODUCT EXPORT_PDF)
    set(oneValueArgs     PRODUCT_DIRECTORY)
    set(multiValueArgs   SOURCES RESOURCE_FILES RESOURCE_DIRS PANDOC_DIRECTIVES DEPENDS)
    cmake_parse_arguments(ADD_PANDOC_DOCUMENT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    # this is because `make clean` will dangerously clean up source files
    disable_insource_build()

    ## set up output directory
    if ("${ADD_PANDOC_DOCUMENT_PRODUCT_DIRECTORY}" STREQUAL "")
        set(ADD_PANDOC_DOCUMENT_PRODUCT_DIRECTORY "product")
    endif()
    get_filename_component(product_directory ${CMAKE_BINARY_DIR}/${ADD_PANDOC_DOCUMENT_PRODUCT_DIRECTORY} ABSOLUTE)
    get_filename_component(absolute_product_path ${product_directory}/${target_name} ABSOLUTE)

    ## get primary source
    set(build_sources)
    foreach(input_file ${ADD_PANDOC_DOCUMENT_SOURCES} )
        pandocology_add_input_file(${CMAKE_CURRENT_SOURCE_DIR}/${input_file} ${CMAKE_CURRENT_BINARY_DIR} build_sources)
    endforeach()

    ## get resource files
    set(build_resources)
    foreach(resource_file ${ADD_PANDOC_DOCUMENT_RESOURCE_FILES})
        pandocology_add_input_file(${CMAKE_CURRENT_SOURCE_DIR}/${resource_file} ${CMAKE_CURRENT_BINARY_DIR} build_resources)
    endforeach()

    ## get resource dirs
    set(exported_resources)
    foreach(resource_dir ${ADD_PANDOC_DOCUMENT_RESOURCE_DIRS})
        pandocology_add_input_dir(${CMAKE_CURRENT_SOURCE_DIR}/${resource_dir} ${CMAKE_CURRENT_BINARY_DIR} build_resources)
        if (${ADD_PANDOC_DOCUMENT_EXPORT_ARCHIVE})
            pandocology_add_input_dir(${CMAKE_CURRENT_SOURCE_DIR}/${resource_dir} ${product_directory} exported_resources)
        endif()
    endforeach()

    ## primary command
    add_custom_command(
        OUTPUT  ${absolute_product_path}
        DEPENDS ${build_sources} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}
        # WORKING_DIRECTORY ${working_directory}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${product_directory}
        # COMMAND ${PANDOC_EXECUTABLE} ${build_sources} ${ADD_PANDOC_DOCUMENT_PANDOC_DIRECTIVES} -o ${absolute_product_path}
        # we produce the target in the source directory, in case other build targets require it as a source
        COMMAND ${PANDOC_EXECUTABLE} ${build_sources} ${ADD_PANDOC_DOCUMENT_PANDOC_DIRECTIVES} -o ${target_name}
        )
    add_to_make_clean(${CMAKE_CURRENT_BINARY_DIR}/${target_name})

    ## primary target
    # # target cannot have same (absolute name) as dependencies:
    # # http://www.cmake.org/pipermail/cmake/2011-March/043378.html
    add_custom_target(
        ${target_name}
        ALL
        DEPENDS ${absolute_product_path} ${ADD_PANDOC_DOCUMENT_DEPENDS}
        )

    # run post-pdf
    if (${ADD_PANDOC_DOCUMENT_EXPORT_PDF})
        # get_filename_component(stemname ${target_name} NAME_WE)
        pandocology_get_file_stemname(stemname ${target_name})
        add_custom_command(
            TARGET ${target_name} POST_BUILD
            DEPENDS ${target_name} ${build_sources} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}

            # Does not work: custom template used to generate tex is ignored
            # COMMAND ${PANDOC_EXECUTABLE} ${target_name} -f latex -o ${stemname}.pdf

            # (1)   Apparently, both nonstopmode and batchmode produce an output file
            #       even if there was an error. This tricks latexmk into believing
            #       the file is actually up-to-date.
            #       So we use `-halt-on-error` or `-interaction=errorstopmode`
            #       instead.
            # (2)   `grep` returns a non-zero error code if the pattern is not
            #       found. So, in our scheme below to filter the output of
            #       `pdflatex`, it is precisely when there is NO error that
            #       grep returns a non-zero code, which fools CMake into thinking
            #       tex'ing failed.
            #       Hence the need for `| grep ...| cat` or `| grep  || true`.
            #       But we can go better:
            #           latexmk .. || (grep .. && false)
            #       So we can have our cake and eat it too: here we want to
            #       re-raise the error after a successful grep if there was an
            #       error in `latexmk`.
            # COMMAND latexmk -gg -halt-on-error -interaction=nonstopmode -file-line-error -pdf ${target_name} 2>&1 | grep -A8 ".*:[0-9]*:.*" || true
            COMMAND latexmk -gg -halt-on-error -interaction=nonstopmode -file-line-error -pdf ${target_name} 2>/dev/null >/dev/null || (grep -A8 ".*:[0-9]*:.*" ${stemname}.log && false)

            COMMAND ${CMAKE_COMMAND} -E copy ${stemname}.pdf ${product_directory}
            )
        add_to_make_clean(${CMAKE_CURRENT_BINARY_DIR}/${stemname}.pdf)
        add_to_make_clean(${product_directory}/${stemname}.pdf)
    endif()

    ## copy products
    if (NOT ${ADD_PANDOC_DOCUMENT_NO_EXPORT_PRODUCT})
        add_custom_command(
            TARGET ${target_name} POST_BUILD
            DEPENDS ${build_sources} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}
            COMMAND ${CMAKE_COMMAND} -E copy ${target_name} ${product_directory}
            )
        add_to_make_clean(${product_directory}/${target_name})
    endif()

    ## copy resources
    if (${ADD_PANDOC_DOCUMENT_EXPORT_ARCHIVE})
        # get_filename_component(stemname ${target_name} NAME_WE)
        pandocology_get_file_stemname(stemname ${target_name})
        add_custom_command(
            TARGET ${target_name} POST_BUILD
            DEPENDS ${build_sources} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}
            # COMMAND cp ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS} ${product_directory}
            COMMAND ${CMAKE_COMMAND} -E tar cvjf ${product_directory}/${stemname}.tbz ${target_name} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}
            )
        add_to_make_clean(${product_directory}/${stemname}.tbz)
    endif()

    # if (${ADD_PANDOC_DOCUMENT_CREATE_SOURCE_ARCHIVE})
    #     add_custom_command(
    #         OUTPUT  ${absolute_product_path}.tbz
    #         DEPENDS ${build_sources} ${build_resources} ${ADD_PANDOC_DOCUMENT_DEPENDS}
    #         # WORKING_DIRECTORY ${working_directory}
    #         COMMAND ${CMAKE_COMMAND} -E make_directory ${product_directory}/bundle
    #         COMMAND ${CMAKE_COMMAND} -E tar cvjf ${product_directory}/bundle/${target_name}.tbz ${build_sources} ${build_resources}
    #         )
    #     add_custom_target(
    #         ${target_name}_bundle
    #         ALL
    #         DEPENDS ${absolute_product_path}.tbz ${ADD_PANDOC_DOCUMENT_DEPENDS}
    #         )
    # endif()

endfunction(add_pandoc_document source)

