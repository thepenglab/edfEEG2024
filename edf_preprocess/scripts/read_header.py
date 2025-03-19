import argparse
import sys

from src import edf_class


def parse_arguments():
    """
    Parses command-line arguments.

    Returns:
        argparse.Namespace: Parsed arguments.
    """
    parser = argparse.ArgumentParser(description="Read the header of an EDF file.")
    parser.add_argument("file_path", type=str, help="Path to the EDF file")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()

    # Validate the provided file path
    file_path = args.file_path
    if not file_path.endswith(".edf"):
        sys.exit("Error: The provided file is not an EDF file.")

    edf = edf_class.Edffile(file_path)
    header = edf.read_header()
    print(header)
