#!/usr/bin/python

import os
from xml.sax.saxutils import escape

def read_file(filename):
    with open(filename, "r") as f:
        result = f.read()
    return result

def build_template(src_template_path, build_script_path, dst_template_path):
    print "Rebuilding %s" % dst_template_path
    template = read_file(src_template_path).split('[INSERT BUILD SCRIPT HERE]')

    build_script = read_file(build_script_path)
    result = template[0] + escape(build_script) + template[1]

    with open(dst_template_path, "w") as f:
        f.write(result)

def build_fake_template():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    src_template_path = script_dir + "/src/FakeFrameworkTemplateInfo.plist"
    build_script_path = script_dir + "/src/BuildFW.py"
    dst_template_path = os.path.abspath(script_dir + "/../Fake Framework/Templates/Framework & Library/Fake Static iOS Framework.xctemplate/TemplateInfo.plist")
    build_template(src_template_path, build_script_path, dst_template_path)

def build_real_template():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    src_template_path = script_dir + "/src/RealFrameworkTemplateInfo.plist"
    build_script_path = script_dir + "/src/BuildFW.py"
    dst_template_path = os.path.abspath(script_dir + "/../Real Framework/Templates/Framework & Library/Static iOS Framework.xctemplate/TemplateInfo.plist")
    build_template(src_template_path, build_script_path, dst_template_path)

if __name__ == "__main__":
    build_fake_template()
    build_real_template()
