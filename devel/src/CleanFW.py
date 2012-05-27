import logging
import os
import subprocess

log = logging.getLogger('UFW')

def get_slave_environment(local_platform, other_platform):
    ignored = ['LD_MAP_FILE_PATH']
    build_root = os.environ['BUILD_ROOT']
    temp_root = os.environ['TEMP_ROOT']
    newenv = {}
    for key, value in os.environ.items():
        if key not in ignored and not key.startswith('LINK_FILE_LIST_'):
            if build_root in value or temp_root in value:
                newenv[key] = value.replace(local_platform, other_platform)
    return newenv

def get_other_platform():
    local_platform = os.environ['PLATFORM_NAME']
    other_platforms = os.environ['SUPPORTED_PLATFORMS'].split(' ')
    other_platforms.remove(local_platform)
    return other_platforms[0]

def get_slave_project_clean_command():
    local_platform = os.environ['PLATFORM_NAME']
    other_platform = get_other_platform()

    sdk_version = os.environ['SDK_NAME']
    if not sdk_version.startswith(local_platform):
        raise Exception("%s didn't start with %s" % (sdk_version, local_platform))
    sdk_version = sdk_version[len(local_platform):]

    cmd = ["xcodebuild",
           "-project",
           os.environ['PROJECT_FILE_PATH'],
           "-target",
           os.environ['TARGET_NAME'],
           "-configuration",
           os.environ['CONFIGURATION'],
           "-sdk",
           other_platform + sdk_version]
    cmd += ["%s=%s" % (key, value) for key, value in get_slave_environment(local_platform, other_platform).items()]
    cmd += ["UFW_MASTER_PLATFORM=" + os.environ['PLATFORM_NAME']]
    cmd += ['clean']
    return cmd

def print_and_call_slave_build(cmd):
    separator = '=== CLEAN NATIVE TARGET '
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    result = p.communicate()[0].split(separator)
    if len(result) == 1:
        result = result[0]
    else:
        result = separator + result[1]
    log.info("Cmd " + " ".join(cmd) + "\n" + result)
    if p.returncode != 0:
        raise subprocess.CalledProcessError(p.returncode, cmd)

def is_master():
    return os.environ.get('UFW_MASTER_PLATFORM', os.environ['PLATFORM_NAME']) == os.environ['PLATFORM_NAME']

if __name__ == "__main__":
    exe_path = os.environ['BUILT_PRODUCTS_DIR'] + "/" + os.environ['EXECUTABLE_PATH']

    log_handler = logging.StreamHandler()
    log_handler.setFormatter(logging.Formatter("%(name)s (M " + os.environ['PLATFORM_NAME'] + "): %(levelname)s: %(message)s"))
    log.addHandler(log_handler)
    log.setLevel(logging.INFO)

    if is_master() and not os.path.exists(exe_path):
        log.info("Platform %s was cleaned. Cleaning %s as well." % (os.environ['PLATFORM_NAME'], get_other_platform()))
        print_and_call_slave_build(get_slave_project_clean_command())
