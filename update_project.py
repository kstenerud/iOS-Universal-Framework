#!/usr/bin/python

import os
import shutil
import sys
from optparse import OptionParser


encode_table = {"\\": "\\\\", "\"": "\\\"", "\n": "\\n"}
decode_table = dict (zip(encode_table.values(), encode_table.keys()))

if __name__ == "__main__":
    usage = "usage: %prog [options] <project file>"
    desc = "Updates a project file to use the latest version of the universal framework build script."
    optParser = OptionParser(usage=usage, description=desc);
    optParser.add_option("-n",
                         "--nobackup",
                         action="store_false",
                         dest="make_backup",
                         help="Don't make a backup of the project (as myproject.pbxproj.orig)",
                         default=True);
    (options, args) = optParser.parse_args();
    if len(args) != 1:
        optParser.print_help()
        exit(1)

    project_filename = args[0]

    this_script_path = os.path.dirname(os.path.realpath(__file__))
    build_script_path = os.path.join(this_script_path, "devel", "src", "BuildFW.py")
    with open(build_script_path, "r") as f:
        build_script = "".join(encode_table.get(c,c) for c in f.read())

    script_tag = "# TAG: BUILD SCRIPT"

    with open(project_filename, "r") as f:
        project_lines = f.readlines()

    script_indices = []
    for index, item in enumerate(project_lines):
        if script_tag in item:
            script_indices.append(index)
    
    if len(script_indices) == 0:
        print "No script containing \"%s\" found in %s" % (script_tag, project_filename)
        sys.exit(1)

    for script_index in script_indices:
        shellpath_index = script_index - 1
    
        if "shellPath = " not in project_lines[shellpath_index]:
            print "Could not find shellPath for script in %s" % project_filename
            sys.exit(1)
        
        project_lines[shellpath_index] = "                        shellPath = /usr/bin/python;\n"
        project_lines[script_index] = "                        shellScript = \"" + build_script + "\";\n"
    
    if options.make_backup:
        shutil.move(project_filename, project_filename + ".orig")

    with open(project_filename, "w") as f:
        f.writelines(project_lines)
