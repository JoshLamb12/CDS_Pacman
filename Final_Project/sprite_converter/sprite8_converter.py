# dependencies:
# > pip install pillow
# > pip install numpy
#note: provided by Dr. Calhoun 
from PIL import Image
import numpy as np

path = 'final_map.png'
textfile_name = 'final_map.txt'
image = Image.open(path).convert('RGB')
image = np.array(image)

img_dims = image.shape

xdim = img_dims[0]
ydim = img_dims[1]
colors = img_dims[2]

print('Size of image: ' + str(image.shape))
print('X dimensions: ' + str(xdim))
print('Y dimensions: ' + str(ydim))
print('Number of colors: ' + str(colors))

file = open(textfile_name, 'w+')

if (np.array_equal(image[0][0],[0, 0, 0])):
    print(image[0][0])
else: 
    print('not equal')

for xx in range (0,xdim):
    img_str = []
    for yy in range (0,ydim):
        if (np.array_equal(image[xx][yy],[0, 0, 0])):
            is_background = 1
        else:
            is_background = 0
        img_str.append("\"")
        img_str.append(f'{0:01b}')
        img_str.append(f'{0:01b}')    
        img_str.append(f'{0:01b}')
        img_str.append(f'{is_background:01b}')
        img_str.append(f'{image[xx][yy][0]:08b}') # R
        img_str.append(f'{image[xx][yy][1]:08b}') # G
        img_str.append(f'{image[xx][yy][2]:08b}') # B
        img_str.append("\"")
        
        if not((xx == xdim-1) and (yy == ydim-1)):
            img_str.append(",")
    
    line = "".join(img_str)
    file.write(line + '\n')


file.close()

