import argparse
import sys

from pyedflib import highlevel


def read_header(file_path):
    """
    Reads the header of an EDF file using pyEDFlib.

    Args:
        file_path (str): Path to the EDF file.

    Returns:
        dict: EDF file header metadata.
    """
    try:
        header = highlevel.read_edf_header(file_path)
        return header
    except Exception as e:
        sys.exit(f"Error reading EDF header: {e}")


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

    header = read_header(file_path)
    print(header)
