import cv2
import numpy as np
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans

###color detection
def reshape_and_convert(img):
    #Micsorarea imaginii ca sa mearga mai rapid procesarea
    img = cv2.resize(img,(0,0),fx=0.5, fy=0.5)

    #Convertire bgr -> rgb
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    #Reshape pt algoritmul de KMeans
    w, h, channels = tuple(img.shape)
    img = np.reshape(img, (w * h, channels))

    return img

def get_dominant_colors(img, n_colors=10):
    img=reshape_and_convert(img)

    kmeans_model = KMeans(n_clusters = n_colors, random_state = 42).fit(img)

    labels, counts = np.unique(kmeans_model.labels_, return_counts=True)
    sorted_indices = np.argsort(counts)[::-1]
    
    dominant_colors = kmeans_model.cluster_centers_[sorted_indices]
    
    return dominant_colors.astype(int)


image = cv2.imread('proiect_connatix/assets/tricou4.jpg')
color_list = get_dominant_colors(image)
plt.imshow([color_list])
plt.show()

###color naming - da eroare
"""
def color_naming(color):
    #color = cv2.cvtColor(color,cv2.COLOR_RGB2HSV)
    hue, saturation, value = color
    color_name = 'undefined'
    if hue < 5:
        color_name = 'red'
    elif hue < 22:
        color_name = 'orange'
    elif hue < 33:
        color_name = 'yellow'
    elif hue < 78:
        color_name = 'green'
    elif hue < 131:
        color_name = 'blue'
    elif hue < 170:
        color_name = 'violet'
    else:
        color_name = 'red'

    return color_name

#print(color_naming(color_list[0]))
#print(color_naming(color_list[1]))
#print(color_naming(color_list[2]))
"""