# -*- coding: utf-8 -*-
"""
Created on Mon Apr 14 09:54:35 2025

@author: adiag
"""

import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')
import os

os.chdir(r'D:\OneDrive - Northeastern University\Jupyter Notebook\Readme Generator')

file = './data/RESOURCES TO LEARN DATA SCIENCE 1926d0dcc058805b8936c15a48ab0cdb.md'

# Open and read a markdown file
with open(file, 'r', encoding='utf-8') as file:
    content = file.read()

print(content)