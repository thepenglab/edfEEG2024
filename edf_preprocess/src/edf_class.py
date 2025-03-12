import sys
from dataclasses import dataclass

from pyedflib import highlevel


@dataclass
class Edffile:
    file_path: str

    def read_header(self):
        """
        Reads the header of an EDF file using pyEDFlib.

        Returns:
            dict: EDF file header metadata.
        """
        try:
            header = highlevel.read_edf_header(self.file_path)
            return header
        except Exception as e:
            sys.exit(f"Error reading EDF header: {e}")
