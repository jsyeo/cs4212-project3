from __future__ import print_function
import os
import subprocess
import sys
import glob

def main():
    test_path = os.path.dirname(os.path.realpath(__file__))
    parser_path = test_path + "/../jlite_main.native"
    files = glob.glob(test_path + "/*.jl")
    tests_num = len(files)
    passes = 0
    for f in files:
        cmd = [parser_path, f]

        debug_str = "executing: " + str(cmd)
        print("=" * len(debug_str))
        print(debug_str)
        print("=" * len(debug_str))
        exit_code = subprocess.call(cmd)
        if exit_code == 0:
            print("{0} passed.".format(f))
            passes = passes + 1
        else:
            print("{0} failed.".format(f))
    print("{0} out of {1} test passed".format(passes, tests_num))

if __name__ == "__main__":
    main()
