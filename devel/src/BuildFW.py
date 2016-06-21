# TAG: BUILD SCRIPT (do not remove this comment)
# Build script generated using https://github.com/kstenerud/iOS-Universal-Framework Mk 8 (beta 2012-06-16)
import logging


##############################################################################
#
# Configuration
#
##############################################################################

# Select which kind of framework to build.
#
# Note: Due to issues with Xcode's build process, if you select
#       'embeddedframework', it will still show the regular framework
#       (as a symlink) along side of the embedded framework. Be sure to
#       instruct your users to copy/move the embedded framework in this case!
#
# If your framework contains resources such as images, nibs, momds, plists,
# zipfiles and such, choose 'embeddedframework'.
#
# If your framework contains no resources, choose 'framework'.
#
config_framework_type = 'framework'
#config_framework_type = 'embeddedframework'

# Open the build directory in Finder when the universal framework is
# successfully built.
#
# This value can be overridden by setting the UFW_OPEN_BUILD_DIR env variable
# to True or False.
#
# Recommended setting: True
#
config_open_build_dir = True

# If true, ensures that all public headers are stored in the framework under
# the same directory hierarchy as they were in the source tree.
#
# Xcode by default places all headers at the same top level, but every other
# build tool in the known universe preserves directory structure. For simple
# libraries it doesn't really matter much, but for ports of existing software
# packages or for bigger libraries, it makes sense to have more structure.
#
# The default is set to "False" since that's what most Xcode users are used to.
#
# Recommended setting: True for deep hierarchy projects, False otherwise.
#
config_deep_header_hierarchy = False

# Specify where the top of the public header hierarchy is. This path is
# relative to the project's dir (PROJECT_DIR). You can reference environment
# variables using templating syntax (e.g. "${TARGET_NAME}/Some/Subdir")
#
# NOTE: Only used if config_deep_header_hierarchy is True.
#
# If this is set to None, the script will attempt to figure out for itself
# where the top of the header hierarchy is by looking for common path prefixes
# in the public header files. This process can fail if:
# - You only have one public header file.
# - Your source header files don't all have a common root.
#
# A common approach is to use "${TARGET_NAME}", working under the assumption
# that all of your header files share the common root of a directory under
# your project with the same name as your target (which is the Xcode default).
#
# Recommended setting: "${TARGET_NAME}"
#
config_deep_header_top = "${TARGET_NAME}"

# Warn when "DerivedData" is detected in any of the header, library, or
# framework search paths. In almost all cases, references to directories under
# DerivedData are added as a result of an Xcode bug and must be manually
# removed.
#
# Recommended setting: True
#
config_warn_derived_data = True

# Warn if no headers were marked public in this framework.
#
# Recommended setting: True
#
config_warn_no_public_headers = True

# Cause the build to fail if any warnings are issued.
#
# Recommended setting: True
#
config_fail_on_warnings = True

# Minimum log level
#
# Recommended setting: logging.INFO
#
config_log_level = logging.INFO


##############################################################################
#
# Don't touch anything below here unless you know what you're doing.
#
##############################################################################

import collections
import json
import os
import re
import shlex
import shutil
import string
import subprocess
import sys
import time
import traceback


##############################################################################
#
# Globals
#
##############################################################################

log = logging.getLogger('UFW')

issued_warnings = False


##############################################################################
#
# Classes
#
##############################################################################

# Allows the slave build to communicate with the master build.
#
class BuildState:

    def __init__(self):
        self.reload()

    def reset(self):
        self.slave_platform = None
        self.slave_architectures = []
        self.slave_linked_archive_paths = []
        self.slave_built_fw_path = None
        self.slave_built_embedded_fw_path = None

    def set_slave_properties(self, architectures,
                             linked_archive_paths,
                             built_fw_path,
                             built_embedded_fw_path):
        self.slave_platform = os.environ['PLATFORM_NAME']
        self.slave_architectures = architectures
        self.slave_linked_archive_paths = linked_archive_paths
        self.slave_built_fw_path = built_fw_path
        self.slave_built_embedded_fw_path = built_embedded_fw_path

    def get_save_path(self):
        return os.path.join(os.environ['PROJECT_TEMP_DIR'], "ufw_build_state.json")

    def persist(self):
        filename = self.get_save_path()
        parent = os.path.dirname(filename)
        if not os.path.isdir(parent):
            os.makedirs(parent)
        with open(filename, "w") as f:
            f.write(json.dumps(self.__dict__))

    def reload(self):
        self.reset()
        filename = self.get_save_path()
        if os.path.exists(filename):
            with open(filename, "r") as f:
                new_dict = json.loads(f.read())
                if new_dict is not None:
                    self.__dict__ = dict(self.__dict__.items() + new_dict.items())


# Holds information about the current project and build environment.
#
class Project:

    def __init__(self, filename):
        sourcecode_types = ['sourcecode.c.c',
                            'sourcecode.c.objc',
                            'sourcecode.cpp.cpp',
                            'sourcecode.cpp.objcpp',
                            'sourcecode.asm.asm',
                            'sourcecode.asm.llvm',
                            'sourcecode.nasm']

        self.build_state = BuildState()
        self.project_data = self.load_from_file(filename)
        self.target = filter(lambda x: x['name'] == os.environ['TARGET_NAME'], self.project_data['targets'])[0]
        self.public_headers = self.get_build_phase_files('PBXHeadersBuildPhase', lambda x: x.get('settings', False) and x['settings'].get('ATTRIBUTES', False) and 'Public' in x['settings']['ATTRIBUTES'])
        self.static_libraries = self.get_build_phase_files('PBXFrameworksBuildPhase', lambda x: x['fileRef']['fileType'] == 'archive.ar' and x['fileRef']['sourceTree'] not in ['DEVELOPER_DIR', 'SDKROOT'])
        self.static_frameworks = self.get_build_phase_files('PBXFrameworksBuildPhase', lambda x: x['fileRef']['fileType'] == 'wrapper.framework' and x['fileRef']['sourceTree'] not in ['DEVELOPER_DIR', 'SDKROOT'])
        self.compilable_sources = self.get_build_phase_files('PBXSourcesBuildPhase', lambda x: x['fileRef']['fileType'] in sourcecode_types)
        self.header_paths = [os.path.join(*x['pathComponents']) for x in self.public_headers]

        self.headers_dir = os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['CONTENTS_FOLDER_PATH'], 'Headers')
        self.libtool_path = os.path.join(os.environ['DT_TOOLCHAIN_DIR'], 'usr', 'bin', 'libtool')
        self.project_filename = os.path.join(os.environ['PROJECT_FILE_PATH'], "project.pbxproj")
        self.local_exe_path = os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['EXECUTABLE_PATH'])
        self.local_architectures = os.environ['ARCHS'].split(' ')
        self.local_built_fw_path = os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['WRAPPER_NAME'])
        self.local_built_embedded_fw_path = os.path.splitext(self.local_built_fw_path)[0] + ".embeddedframework"
        self.local_linked_archive_paths = [self.get_linked_ufw_archive_path(arch) for arch in self.local_architectures]
        self.local_platform = os.environ['PLATFORM_NAME']
        other_platforms = os.environ['SUPPORTED_PLATFORMS'].split(' ')
        other_platforms.remove(self.local_platform)
        self.other_platform = other_platforms[0]

        sdk_name = os.environ['SDK_NAME']
        if not sdk_name.startswith(self.local_platform):
            raise Exception("%s didn't start with %s" % (sdk_name, self.local_platform))
        self.sdk_version = sdk_name[len(self.local_platform):]

    # Load an Xcode project file.
    #
    def load_from_file(self, filename):
        project_file = json.loads(subprocess.check_output(["plutil", "-convert", "json", "-o", "-", filename]))
        all_objects = project_file['objects']
        del project_file['objects']
        for obj in all_objects.values():
            self.fix_keys(obj)
        self.unpack_objects(self.build_dereference_list(all_objects, None, None, project_file))
        self.unpack_objects(self.build_dereference_list(all_objects, None, None, all_objects.values()))
        project_data = project_file['rootObject']
        self.build_full_paths(project_data, splitpath(os.environ['SOURCE_ROOT']))
        return project_data

    def is_key(self, obj):        
        return isinstance(obj, basestring) and len(obj) == 24 and re.search('^[0-9a-fA-F]+$', obj) is not None
    
    def build_dereference_list(self, all_objects, parent, key, obj):
        deref_list = []
        if self.is_key(obj):
            dereferenced = all_objects.get(obj, obj)
            if dereferenced is not obj:
                deref_list.append((parent, key, obj, dereferenced))
        elif isinstance(obj, collections.Mapping):
            for k, v in obj.iteritems():
                deref_list += self.build_dereference_list(all_objects, obj, k, v)
        elif isinstance(obj, collections.Iterable) and not isinstance(obj, basestring):
            for item in obj:
                deref_list += self.build_dereference_list(all_objects, obj, None, item)
        return deref_list
    
    def unpack_objects(self, deref_list):
        for parent, key, orig, obj in deref_list:
            if key is None:
                parent.remove(orig)
                parent.append(obj)
            else:
                parent[key] = obj

    # Store the full path, separated into components, to a node inside the node
    # as "pathComponents". Also recurse into that node if it's a group.
    #
    def build_full_paths(self, node, base_path):
        # Some nodes are relative to a different source tree, specified as an
        # env variable.
        if node.get('sourceTree', '<group>') != '<group>':
            new_base_path = os.environ.get(node['sourceTree'], None)
            if new_base_path:
                base_path = splitpath(new_base_path)
        # Add the current node's path, if any.
        if node.get('path', False):
            base_path = base_path + splitpath(node['path'])
        node['pathComponents'] = base_path
        # Recurse if this is a group.
        if node['isa'] == 'PBXGroup':
            for child in node['children']:
                self.build_full_paths(child, base_path)
        elif node['isa'] == 'PBXProject':
            self.build_full_paths(node['mainGroup'], base_path)
            self.build_full_paths(node['productRefGroup'], base_path)
            for child in node['targets']:
                self.build_full_paths(child, base_path)
            projectRefs = node.get('projectReferences', None)
            if projectRefs is not None:
                for child in projectRefs[0].values():
                    self.build_full_paths(child, base_path)

    # Fix up any inconvenient keys.
    #
    def fix_keys(self, obj):
        key_remappings = {'lastKnownFileType': 'fileType', 'explicitFileType': 'fileType'}
        for key in list(set(key_remappings.keys()) & set(obj.keys())):
            obj[key_remappings[key]] = obj[key]
            del obj[key]

    # Get the files from a build phase.
    #
    def get_build_phase_files(self, build_phase_name, filter_func):
        build_phase = filter(lambda x: x['isa'] == build_phase_name, self.target['buildPhases'])[0]
        build_files = filter(filter_func, build_phase['files'])
        return [x['fileRef'] for x in build_files]

    # Get the truncated paths of all headers that start with the specified
    # relative path. Paths are read and returned as fully separated lists.
    # e.g. ['Some', 'Path', 'To', 'A', 'Header'] with relative_path of
    # ['Some', 'Path'] gets truncated to ['To', 'A', 'Header']
    #
    def movable_headers_relative_to(self, relative_path):
        rel_path_length = len(relative_path)
        result = filter(lambda path: len(path) >= rel_path_length and
                                     path[:rel_path_length] == relative_path, self.header_paths)
        return [path[rel_path_length:] for path in result]

    # Get the full path to where a linkable archive (library or framework)
    # is supposed to be.
    #
    def get_linked_archive_path(self, architecture):
        return os.path.join(os.environ['OBJECT_FILE_DIR_%s' % os.environ['CURRENT_VARIANT']],
                            architecture,
                            os.environ['EXECUTABLE_NAME'])

    # Get the full path to our custom linked archive of the project.
    #
    def get_linked_ufw_archive_path(self, architecture):
        return self.get_linked_archive_path(architecture) + ".ufwbuild"

    # Get the full path to the executable of an archive.
    #
    def get_exe_path(self, node):
        path = os.path.join(*node['pathComponents'])
        if node['fileType'] == 'wrapper.framework':
            # Frameworks are directories, so go one deeper
            path = os.path.join(path, os.path.splitext(node['pathComponents'][-1])[0])
        return path

    # Get the path to the directory containing the archive.
    #
    def get_containing_path(self, node):
        return os.path.join(*node['pathComponents'])
    
    def get_archive_search_paths(self):
        log.info("Search paths = %s" % set([self.get_containing_path(fw) for fw in self.static_frameworks] + [self.get_containing_path(fw) for fw in self.static_libraries]))
        return set([self.get_containing_path(fw) for fw in self.static_frameworks] + [self.get_containing_path(fw) for fw in self.static_libraries])

    # Command to link all objects of a single architecture.
    #
    def get_single_arch_link_command(self, architecture):
        cmd = [self.libtool_path,
               "-static",
               "-arch_only", architecture,
               "-syslibroot", os.environ['SDKROOT'],
               "-L%s" % os.environ['TARGET_BUILD_DIR'],
               "-filelist", os.environ['LINK_FILE_LIST_%s_%s' % (os.environ['CURRENT_VARIANT'], architecture)]]
        if os.environ.get('OTHER_LDFLAGS', False):
            cmd += [os.environ['OTHER_LDFLAGS']]
        if os.environ.get('WARNING_LDFLAGS', False):
            cmd += [os.environ['WARNING_LDFLAGS']]
#        cmd += ["-L%s" % libpath for libpath in self.get_archive_search_paths()]
        cmd += [self.get_exe_path(fw) for fw in self.static_frameworks]
        cmd += [self.get_exe_path(lib) for lib in self.static_libraries]
        cmd += ["-o", self.get_linked_ufw_archive_path(architecture)]
        return cmd

    # Command to link all local architectures for the current configuration
    # into an archive. This reads all libraries + the UFW-built archives and
    # overwrites the final product.
    #
    def get_local_archs_link_command(self):
        cmd = [self.libtool_path,
               "-static"]
        cmd += self.local_linked_archive_paths
        cmd += [self.get_exe_path(fw) for fw in self.static_frameworks]
        cmd += [self.get_exe_path(lib) for lib in self.static_libraries]
        cmd += ["-o", os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['EXECUTABLE_PATH'])]
        return cmd

    # Command to link all architectures into a universal archive.
    # This reads all UFW-built archives and overwrites the final product.
    #
    def get_all_archs_link_command(self):
        cmd = [self.libtool_path,
               "-static"]
        cmd += self.local_linked_archive_paths + self.build_state.slave_linked_archive_paths
        cmd += ["-o", os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['EXECUTABLE_PATH'])]
        return cmd

    # Build up an environment for the slave process. This uses BUILD_ROOT
    # and TEMP_ROOT to convert all environment variables to values suitable
    # for the slave build environment so that xcodebuild doesn't try to build
    # in the project directory under "build".
    #
    def get_slave_environment(self):
        ignored = ['LD_MAP_FILE_PATH',
        'HEADER_SEARCH_PATHS',
        'LIBRARY_SEARCH_PATHS',
        'FRAMEWORK_SEARCH_PATHS']
        build_root = os.environ['BUILD_ROOT']
        temp_root = os.environ['TEMP_ROOT']
        newenv = {}
        for key, value in os.environ.items():
            if key not in ignored and not key.startswith('LINK_FILE_LIST_') and not key.startswith('LD_DEPENDENCY_'):
                if build_root in value or temp_root in value:
                    newenv[key] = value.replace(self.local_platform, self.other_platform)
        return newenv

    # Command to invoke xcodebuild on the slave platform.
    #
    def get_slave_project_build_command(self):
        cmd = ["xcodebuild",
               "-project",
               os.environ['PROJECT_FILE_PATH'],
               "-target",
               os.environ['TARGET_NAME'],
               "-configuration",
               os.environ['CONFIGURATION'],
               "-sdk",
               self.other_platform + self.sdk_version]
        cmd += ["%s=%s" % (key, value) for key, value in self.get_slave_environment().items()]
        cmd += ["UFW_MASTER_PLATFORM=" + os.environ['PLATFORM_NAME']]
        cmd += [os.environ['ACTION']]
        return cmd



##############################################################################
#
# Utility Functions
#
##############################################################################

# Split a path into a list of path components.
#
def splitpath(path, maxdepth=20):
     (head, tail) = os.path.split(path)
     return splitpath(head, maxdepth - 1) + [tail] if maxdepth and head and head != path else [ head or tail ]

# Remove all subdirectories under a path.
#
def remove_subdirs(path, ignore_files):
    if os.path.exists(path):
        for filename in filter(lambda x: x not in ignore_files, os.listdir(path)):
            fullpath = os.path.join(path, filename)
            if os.path.isdir(fullpath):
                log.info("Remove %s" % fullpath)
                shutil.rmtree(fullpath)

# Make whatever parent paths are necessary for a path to exist.
#
def ensure_path_exists(path):
    if not os.path.isdir(path):
        os.makedirs(path)

# Make whatever parent paths are necessary for a path's parent to exist.
#
def ensure_parent_exists(path):
    parent = os.path.dirname(path)
    if not os.path.isdir(parent):
        os.makedirs(parent)

# Remove a file or dir if it exists.
#
def remove_path(path):
    if os.path.exists(path):
        if os.path.isdir(path) and not os.path.islink(path):
            shutil.rmtree(path)
        else:
            os.remove(path)

# Move a file (not a directory), replacing the destination if it exists.
#
def move_file(src, dst):
    if src == dst or not os.path.isfile(src):
        return
    log.info("Move file %s to %s" % (src, dst))
    ensure_parent_exists(dst)
    remove_path(dst)
    shutil.move(src, dst)

# Move a directory (not a file), replacing the destination if it exists.
#
def move_dir(src, dst):
    if src == dst or not os.path.isdir(src):
        return
    log.info("Move dir %s to %s" % (src, dst))
    ensure_parent_exists(dst)
    remove_path(dst)
    shutil.move(src, dst)

# Move a file OR directory, replacing the destination if it exists.
#
def move_file_or_dir(src, dst):
    if src == dst or not os.path.exists(src):
        return
    log.info("Move file/dir %s to %s" % (src, dst))
    ensure_parent_exists(dst)
    remove_path(dst)
    shutil.move(src, dst)

# Copy a file or dir, replacing the destination if it exists already.
#
def copy_overwrite(src, dst):
    if src != dst:
        remove_path(dst)
        ensure_parent_exists(dst)
        shutil.copytree(src, dst, symlinks=True)

# Attempt to symlink link_path -> link_to.
# link_to must be a path relative to link_path's parent and must exist.
# If link_path already exists, do nothing.
#
def attempt_symlink(link_path, link_to):
    # Only allow linking to an existing file
    os.stat(os.path.abspath(os.path.join(link_path, "..", link_to)))

    # Only make the link if it hasn't already been made
    if not os.path.exists(link_path):
        log.info("Symlink %s -> %s" % (link_path, link_to))
        os.symlink(link_to, link_path)

# Takes the last entry in an array-based path and returns a normal path
# relative to base_path.
#
def top_level_file_path(base_path, path_list):
    return os.path.join(base_path, os.path.split(path_list[-1])[-1])

# Takes all entries in an array-based path and returns a normal path
# relative to base_path.
#
def full_file_path(base_path, path_list):
    return os.path.join(*([base_path] + path_list))

# Print a command before executing it.
# Also print out all output from the command to STDOUT.
#
def print_and_call(cmd):
    log.info("Cmd " + " ".join(cmd))
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    result = p.communicate()[0]
    if len(result) > 0:
        log.info(result)
    if p.returncode != 0:
        raise subprocess.CalledProcessError(p.returncode, cmd)

# Special print-and-call command for the slave build that strips out
# xcodebuild's spammy list of environment variables.
#
def print_and_call_slave_build(cmd, other_platform):
    separator = '=== BUILD NATIVE TARGET '
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    result = p.communicate()[0].split(separator)
    if len(result) == 1:
        result = result[0]
    else:
        result = separator + result[1]
    log.info("Cmd " + " ".join(cmd) + "\n" + result)
    if p.returncode != 0:
        raise subprocess.CalledProcessError(p.returncode, cmd)

# Issue a warning and record that a warning has been issued.
#
def issue_warning(msg, *args, **kwargs):
    global issued_warnings
    issued_warnings = True
    log.warn(msg, *args, **kwargs)



##############################################################################
#
# Main Application
#
##############################################################################

# Check if we are running as master.
#
def is_master():
    return os.environ.get('UFW_MASTER_PLATFORM', os.environ['PLATFORM_NAME']) == os.environ['PLATFORM_NAME']

# DerivedData should almost never appear in any framework, library, or header
# search paths. However, Xcode will sometimes add them in, so we check to make
# sure.
#
def check_for_derived_data_in_search_paths(project):
    search_path_keys = ["FRAMEWORK_SEARCH_PATHS", "LIBRARY_SEARCH_PATHS", "HEADER_SEARCH_PATHS"]
    build_configs = project.target['buildConfigurationList']['buildConfigurations']
    build_settings = filter(lambda x: x['name'] == os.environ['CONFIGURATION'], build_configs)[0]['buildSettings']
    
    found_something = False
    for path_key in filter(lambda x: x in build_settings, search_path_keys):
        path = build_settings[path_key]
        if "DerivedData" in path:
            found_something = True
            log.warn("Derived data in %s" % path)
            issue_warning("'%s' contains reference to 'DerivedData'." % path_key)
    if found_something:
        log.warn("Check your build settings and remove any entries that contain paths inside the DerivedData folder.")
        log.warn("Otherwise you can disable this warning by changing 'config_warn_derived_data' in this script.")

# Link local architectures into their respective archives.
#
def link_local_archs(project):
    for arch in project.local_architectures:
        print_and_call(project.get_single_arch_link_command(arch))

# Link only the local architectures into the final product, not the slave
# architectures. For iphoneos, this will be armv6, armv7. For simulator, this
# will be i386.
#
def link_combine_local_archs(project):
    print_and_call(project.get_local_archs_link_command())

# Link all architectures into the final product.
#
def link_combine_all_archs(project):
    print_and_call(project.get_all_archs_link_command())

# Check if we should open the build directory after a successful build.
#
def should_open_build_dir():
    env_setting = os.environ.get('UFW_OPEN_BUILD_DIR', None)
    if env_setting is not None:
        return env_setting
    
    # If building on Xcode Bots shouldn't open build directory.
    build_user = os.environ['USER']
    if build_user == '_teamsserver':
        return False

    return config_open_build_dir

# Open the build dir in Finder.
#
def open_build_dir():
    print_and_call(['open', os.environ['TARGET_BUILD_DIR']])

# Check if the build was started by selecting "Archive" under "Product" in
# Xcode.
#
def is_archive_build():
    # ACTION is always 'build', but perhaps Apple will fix this someday?
    archive_build = os.environ['ACTION'] == 'archive'

    if not archive_build:
        # This can be passed in as an env variable when building from command line.
        archive_build = os.environ.get('UFW_ACTION', None) == 'archive'

    build_dir = splitpath(os.environ['BUILD_DIR'])
    if not archive_build:
        # This partial path is used when you select "archive" from within Xcode.
        archive_build = 'ArchiveIntermediates' in build_dir

    # It only counts as a full archive build if this target is being built into
    # its own build dir (not being built as a dependency of another target)
    if archive_build:
        archive_build = os.environ['TARGET_NAME'] in build_dir
    
    return archive_build

# Xcode by default throws all public headers into the top level directory.
# This function moves them to their expected deep hierarchy.
#
def build_deep_header_hierarchy(project):
    header_path_top = config_deep_header_top
    if not header_path_top:
        header_path_top = os.path.commonprefix(project.header_paths)
    else:
        header_path_top = splitpath(header_path_top)

    built_headers_path = os.path.join(os.environ['TARGET_BUILD_DIR'], os.environ['PUBLIC_HEADERS_FOLDER_PATH'])
    movable_headers = project.movable_headers_relative_to(header_path_top)

    # Remove subdirs if they only contain files that have been rebuilt
    ignore_headers = filter(lambda x: not os.path.isfile(top_level_file_path(built_headers_path, x)), movable_headers)
    remove_subdirs(built_headers_path, [file[0] for file in ignore_headers])

    # Move rebuilt headers into their proper subdirs
    for header in movable_headers:
        move_file(top_level_file_path(built_headers_path, header), full_file_path(built_headers_path, header))

# Add all symlinks needed to make a full framework structure:
#
# MyFramework.framework
# |-- MyFramework -> Versions/Current/MyFramework
# |-- Headers -> Versions/Current/Headers
# |-- Resources -> Versions/Current/Resources
# `-- Versions
#     |-- A
#     |   |-- MyFramework
#     |   |-- Headers
#     |   |   `-- MyFramework.h
#     |   `-- Resources
#     |       |-- Info.plist
#     |       |-- MyViewController.nib
#     |       `-- en.lproj
#     |           `-- InfoPlist.strings
#     `-- Current -> A
#
def add_symlinks_to_framework(project):
    base_dir = project.local_built_fw_path
    attempt_symlink(os.path.join(base_dir, "Versions", "Current"), os.environ['FRAMEWORK_VERSION'])
    if os.path.isdir(os.path.join(base_dir, "Versions", "Current", "Headers")):
        attempt_symlink(os.path.join(base_dir, "Headers"), os.path.join("Versions", "Current", "Headers"))
    if os.path.isdir(os.path.join(base_dir, "Versions", "Current", "Resources")):
        attempt_symlink(os.path.join(base_dir, "Resources"), os.path.join("Versions", "Current", "Resources"))
    attempt_symlink(os.path.join(base_dir, os.environ['EXECUTABLE_NAME']), os.path.join("Versions", "Current", os.environ['EXECUTABLE_NAME']))

# Build an embedded framework structure.
# An embedded framework contains the actual framework, plus a "Resources"
# directory containing symlinks to all resources found in the actual framework,
# with the exception of "Info.plist" and anything ending in ".lproj".
# Also, compiled storyboards are not symlinked becuase iOS can't handle that - they are moved from the framework's Resources directory to the embeddedframework's Resources directory:
#
# MyFramework.embeddedframework
# |-- MyFramework.framework
# |   |-- MyFramework -> Versions/Current/MyFramework
# |   |-- Headers -> Versions/Current/Headers
# |   |-- Resources -> Versions/Current/Resources
# |   `-- Versions
# |       |-- A
# |       |   |-- MyFramework
# |       |   |-- Headers
# |       |   |   `-- MyFramework.h
# |       |   `-- Resources
# |       |       |-- Info.plist
# |       |       |-- MyViewController.nib
# |       |       `-- en.lproj
# |       |           `-- InfoPlist.strings
# |       `-- Current -> A
# `-- Resources
#     `-- MyViewController.nib -> ../MyFramework.framework/Resources/MyViewController.nib
#     -- MyStoryboard.storyboardc
#
def build_embedded_framework(project):
    fw_path = project.local_built_fw_path
    embedded_path = project.local_built_embedded_fw_path
    fw_name = os.environ['WRAPPER_NAME']

    if (os.path.islink(fw_path)):
        # If the framework path is a link, the build result already in embeddedframework.
        # Just recreate embeddedframework's Resources
        remove_path(os.path.join(embedded_path, "Resources"))
    else:
        remove_path(embedded_path)
        ensure_path_exists(embedded_path)
        copy_overwrite(fw_path, os.path.join(embedded_path, fw_name))

    # Create embeddedframework's Resources        
    ensure_path_exists(os.path.join(embedded_path, "Resources"))
    symlink_source = os.path.join("..", fw_name, "Resources")
    symlink_path = os.path.join(embedded_path, "Resources")
    if os.path.isdir(os.path.join(fw_path, "Resources")):
        for file in filter(lambda x: x != "Info.plist" and not x.endswith(".lproj") and not x.endswith(".storyboardc"), os.listdir(os.path.join(fw_path, "Resources"))):
            log.info("symlinking resource file: " + file)
            attempt_symlink(os.path.join(symlink_path, file), os.path.join(symlink_source, file))
        for file in filter(lambda x: x.endswith(".storyboardc"), os.listdir(os.path.join(fw_path, "Resources"))):
            src = os.path.join(embedded_path, fw_name, "Resources", file)
            dst = os.path.join(symlink_path, file)
            log.info("moving storyboard instead of symlinking it: " + file)
            move_file_or_dir(src,dst) #storyboards are directories apparently

    # Remove the normal framework and replace it with a symlink to the copy
    # in the embedded framework. This is needed because Xcode runs its strip
    # phase AFTER the script runs.
    embed_fw_wrapper = os.path.splitext(os.environ['WRAPPER_NAME'])[0] + ".embeddedframework"
    remove_path(fw_path)
    attempt_symlink(fw_path, os.path.join(embed_fw_wrapper, os.environ['WRAPPER_NAME']))


# Run the build process in slave mode to build the other configuration
# (device/simulator).
#
def run_slave_build(project):
    print_and_call_slave_build(project.get_slave_project_build_command(), project.other_platform)

# Run the build process.
#
def run_build():
    project = Project(os.path.join(os.environ['PROJECT_FILE_PATH'], "project.pbxproj"))

    # Issue warnings only if we're master.
    if is_master():
        if len(project.compilable_sources) == 0:
            raise Exception("No compilable sources found. Please add at least one source file to build target %s." % os.environ['TARGET_NAME'])

        if config_warn_derived_data:
            check_for_derived_data_in_search_paths(project)
        if config_warn_no_public_headers and len(project.public_headers) == 0:
            issue_warning('No headers in build target %s were marked public. Please move at least one header to "Public" in the "Copy Headers" build phase.' % os.environ['TARGET_NAME'])

    # Only build slave if this is an archive build.
    if is_archive_build():
        if is_master():
            log.debug("Building as MASTER")
            # The slave-side linker tries to include this (nonexistent) path as
            # a library path.
            ensure_path_exists(project.get_slave_environment()['BUILT_PRODUCTS_DIR'])
            project.build_state.persist()
            run_slave_build(project)
            project.build_state.reload()
        else:
            log.debug("Building as SLAVE")
            project.build_state.reload()
            project.build_state.set_slave_properties(project.local_architectures,
                                                     project.local_linked_archive_paths,
                                                     project.local_built_fw_path,
                                                     project.local_built_embedded_fw_path)
            project.build_state.persist()

    link_local_archs(project)
    
    # Only do a universal binary when building an archive.
    if is_archive_build() and is_master():
        link_combine_all_archs(project)
    else:
        link_combine_local_archs(project)

    if config_deep_header_hierarchy:
        build_deep_header_hierarchy(project)

    add_symlinks_to_framework(project)
    
    if is_master():
        if config_framework_type == 'embeddedframework':
            build_embedded_framework(project)
        elif config_framework_type != 'framework':
            raise Exception("%s: Unknown framework type for config_framework_type" % config_framework_type)


if __name__ == "__main__":
    log_handler = logging.StreamHandler()
    log_handler.setFormatter(logging.Formatter("%(name)s (" + os.environ['PLATFORM_NAME'] + "): %(levelname)s: %(message)s"))
    log.addHandler(log_handler)
    log.setLevel(config_log_level)

    error_code = 0
    prefix = "M" if is_master() else "S"
    log_handler.setFormatter(logging.Formatter("%(name)s (" + prefix + " " + os.environ['PLATFORM_NAME'] + "): %(levelname)s: %(message)s"))

    log.debug("Begin build process")

    if config_deep_header_top:
        config_deep_header_top = string.Template(config_deep_header_top).substitute(os.environ)

    try:
        run_build()
        if issued_warnings:
            if config_fail_on_warnings:
                error_code = 1
            log.warn("Build completed with warnings")
        else:
            log.info("Build completed")
        if not is_archive_build():
            log.info("Note: This is *NOT* a universal framework build. To build as a universal framework, do an archive build.")
            log.info("To do an archive build from command line, use \"xcodebuild -configuration Release UFW_ACTION=archive clean build\"")
    except Exception:
        traceback.print_exc(file=sys.stdout)
        error_code = 1
        log.error("Build failed")
    finally:
        if error_code == 0 and is_archive_build() and is_master():
            log.info("Built framework is in " + os.environ['TARGET_BUILD_DIR'])
            if should_open_build_dir():
                open_build_dir()
        sys.exit(error_code)
