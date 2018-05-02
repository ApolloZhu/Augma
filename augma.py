import cv2
import numpy as np

a = cv2.imread('img.JPG')
cv2.imshow("Display", a)
cv2.waitKey(0)
cv2.destroyAllWindows()
