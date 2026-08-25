import os

# specify the directory you want to search
directory = "/Users/adityaagarwal/Library/CloudStorage/OneDrive-NortheasternUniversity/Jupyter Notebook/Projects"

# get a list of all the subfolders in the directory
subfolders = [f.name for f in os.scandir(directory) if f.is_dir()]

# write the subfolder names to a text file
with open('folder_names.txt', 'w') as file:
    for name in subfolders:
        file.write(name + '\n')