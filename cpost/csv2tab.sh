#!/usr/bin/env python

import sys
import csv
from StringIO import StringIO

csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))