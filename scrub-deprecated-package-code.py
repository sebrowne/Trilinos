import os
import subprocess
import re
import argparse


_VERBOSE = False


ignore_these_macros = {
    "XPETRA_EPETRA_NO_32BIT_GLOBAL_INDICES",
    "XPETRA_EPETRA_NO_64BIT_GLOBAL_INDICES",
    "EPETRA_NO_32BIT_GLOBAL_INDICES",
    "EPETRA_NO_64BIT_GLOBAL_INDICES"
}


def is_cpp_source_file(filename):
    return filename.endswith(('.c', '.cpp', '.h', '.hpp', '.C', '.H', '.hpp.in', '.h.in', '.H.in'))


def filter_rigs(s):
    return not (s.endswith('_H') or s.endswith('_HPP'))


def find_macros_to_remove(directory, regex_pattern):
    pattern = re.compile(regex_pattern)
    macros_to_remove = set()

    for root, dirs, files in os.walk(directory):
        print(f"Scanning ./{os.path.relpath(root, directory)}")
        for file in files:
            if is_cpp_source_file(file):
                file_path = os.path.join(root, file)
                if _VERBOSE:
                    print(f"Scanning file: {os.path.relpath(file_path, directory)}")

                with open(file_path, 'r') as f:
                    content = f.read()
                matches = pattern.findall(content)
                macros = [group for match in matches for group in match if group]
                if _VERBOSE and macros:
                    print(f"    Found macros: {macros}")
                macros_to_remove.update(macros)

    macros_to_remove = set(filter(filter_rigs, macros_to_remove))
    return macros_to_remove - ignore_these_macros


def run_unifdef(directory, macros_to_remove):
    print("\nUsing `unifdef` to remove preprocessor macros")

    with open('undef_macros.tmp', 'w') as temp_file:
        for macro in macros_to_remove:
            temp_file.write(f"#undef {macro}\n")

    for root, _, files in os.walk(directory):
        for file in files:
            if is_cpp_source_file(file):
                file_path = os.path.join(root, file)
                if _VERBOSE:
                    print(f"Processing file: {os.path.relpath(file_path, directory)}")

                try:
                    command = [os.path.join(os.path.dirname(os.path.realpath(__file__)), "unifdef"), '-x', '2', '-B', '-o', file_path, '-f', 'undef_macros.tmp', file_path]
                    
                    result = subprocess.run(command, capture_output=True, text=True)

                    if result.returncode != 0:
                        print(" ".join(command))
                        print(f"Error processing {file_path}: {result.stderr} {result.stdout}")

                except Exception as e:
                    print(f"An error occurred while processing {file_path}: {e}")


def remove_cmakedefines(directory, macros_to_remove):
    print("Removing any '#cmakedefine <DEPRECATED_MACRO>' statements in generated header input files")
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(('.hpp.in', '.h.in')):
                    file_path = os.path.join(root, file)
                    with open(file_path, 'r') as file:
                        lines = file.readlines()
                    output_lines = []
                    for line in lines:
                        if not (line.strip().startswith("#cmakedefine") and any([line.strip().endswith(x) for x in macros_to_remove])):
                            output_lines.append(line)
                        else:
                            print(f"Removing {line} from {file}")

                    with open(file_path, 'w') as file:
                        file.writelines(output_lines)


def scan_and_write_macro_file(target_directory, macro_file):
        print(f"Scanning any C/C++ source/header file recursively starting at '{target_directory}' for macros related to deprecated packages")
        print("\n--> THIS WILL TAKE A LONG TIME <--\n")
        deprecated_packages = [
            "Amesos",
            "AztecOO",
            "Epetra",
            "EpetraExt",
            "Ifpack",
            "Intrepid",
            "Isorropia",
            "ML",
            "NewPackage",
            "Pliris",
            "PyTrilinos",
            "ShyLU_DDCore",
            "ThyraEpetraAdapters",
            "ThyraEpetraExtAdapters",
            "Triutils",
            "DOMI",
            "MOERTEL",
            "FEI",
            "Komplex",
            "Rythmos",
            "Pike",
            "TriKota"
        ]
        regex = r"|".join([fr"\W+({x.upper()}_\w*)\W+|\W+(\w*_{x.upper()})\W+|\W+(\w*_{x.upper()}_\w*)\W+" for x in deprecated_packages])
        macros_to_remove = find_macros_to_remove(target_directory, regex)
        with open(macro_file, 'w') as outf:
            outf.write("\n".join(macros_to_remove))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Scan for preprocessor macros related to deprecated Trilinos packages and remove them appropriately with `unifdef`.  Run this in a directory and it will iterate that directory (e.g. `packages/tpetra`).")
    parser.add_argument("-f", "--fresh", action="store_true", help="Explicitly can for preprocessor macros")
    parser.add_argument("-r", "--remove", action="store_true", help="Run `unifdef` to remove all macros from all C/C++ source/header files")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    _VERBOSE = args.verbose
    macro_file = os.path.join(os.getcwd(), "macros.txt")
    target_directory = os.getcwd()
    if args.fresh:
        scan_and_write_macro_file(target_directory, macro_file)
    else:
        if not os.path.isfile(macro_file):
            print(f"Macro file '{macro_file}' does not exist; scanning fresh")
            scan_and_write_macro_file(target_directory, macro_file)

    print(f"Using '{macro_file}' for macros to remove")
    with open(macro_file, 'r') as inf:
        macros_to_remove = inf.read().splitlines()

    if macros_to_remove:
        print(f"Macros to remove: {macros_to_remove}")
        if args.remove:
            run_unifdef(target_directory, macros_to_remove)
            remove_cmakedefines(target_directory, macros_to_remove)
    else:
        print("\nNo matching macros found!\n")
