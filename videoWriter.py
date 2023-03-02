import cv2
import os
import sys
import pandas as pd
import numpy as np
import nibabel as nb
from PIL import Image
import itertools
import png

# ******IMPORTANT*******

# Run this script in order to create a video from a folder of images. The first argument is the image folder, the second is the name of the output file.
# should look like this on the command line [python videoWriter.py ImageFolderName Video.avi]
# It will write to the working directory

# Open output video.avi in VLC video player for best results.

# **********************
addGroundTruth = False
image_folder = sys.argv[1]

if addGroundTruth:
    print ("Ground Truth == True")
    groundTruthFolder = pd.read_csv(sys.argv[2], sep="\t", header=0)
else:
    pass


video_name = image_folder+'.mp4'

# IMPORTANT NOTE! This must match the recording frames per second in the
# airsim documentation (settings.json). Also, make sure the files are not compressed
fps = 30

print ("Folder of Images, ", image_folder)
print ("Output Video Name, ", video_name)

def AddGroundTruthToImage(image_folder, imageName, groundTruthFolder, i,height, width):
    ''' This function takes the original image and puts the ground truth
        superimposed on the image as a circle if the point lies
        within the camera's FOV'''

    df = groundTruthFolder #pd.read_csv(groundTruthFolder, sep="\t", header=0)
    df['TimeStamp'] = df['TimeStamp'] - df['TimeStamp'][0]

    a_x = 90   # default FOV for camera in airsim.
    x = width/2  #half the image width -- or the length from center
    y = height/2  # same but for height
    f_x = x / 2*np.tan(a_x/2)
    f_y = y / 2*np.tan(a_x/2)
    s = 0
    intrinsics = np.matrix([[f_x, s, x], [0, f_y, y], [0, 0, 1]])

    directionVector = np.zeros([3,1])
    q = np.array([df['Q_W'][i],df['Q_X'][i],df['Q_Y'][i],df['Q_Z'][i]])

    dx = (df['POS_X'][i] - df['POS_X'][i-1])/(df['TimeStamp'][i]-df['TimeStamp'][i-1])
    dy = (df['POS_Y'][i] - df['POS_Y'][i-1])/(df['TimeStamp'][i]-df['TimeStamp'][i-1])
    dz = (df['POS_Z'][i] - df['POS_Z'][i-1])/(df['TimeStamp'][i]-df['TimeStamp'][i-1])

    rotatedVector = nb.quaternions.rotate_vector(np.array([dx, dy, dz]), q)
    theta1 = np.arctan(rotatedVector[1]/rotatedVector[0])
    theta2 = np.arctan(rotatedVector[2]/rotatedVector[1])

    pixelX = np.int64(np.round(f_x*(theta1))) + x
    pixelY = np.int64(np.round(f_y*(theta2))) + y

    newImage = cv2.imread(os.path.join(image_folder, image))
    newImage = cv2.circle(newImage, (pixelX, pixelY), 6, (0,0,255))
    #cv2.imshow('image',newImage)
    #cv2.imwrite(image, newImage)

    return newImage

images = [img for img in os.listdir(image_folder) if img.endswith(".png")]
images = sorted(images)

frame = cv2.imread(os.path.join(image_folder, images[0]))

height, width, layers = frame.shape

video = cv2.VideoWriter(video_name, cv2.VideoWriter_fourcc(*"XVID"), fps, (width,height))

print (len(images))
#print groundTruthFolder.shape

i = 0
for image in images:
    print (i)
    if addGroundTruth and i>=1:
        newImage = AddGroundTruthToImage(image_folder, image, groundTruthFolder,i,height, width)
        cv2.imshow('image', newImage)

        video.write(newImage)

    else:
        video.write(cv2.imread(os.path.join(image_folder, image)))


    i += 1

cv2.destroyAllWindows()
video.release()


print ("...Video Writing Complete")
