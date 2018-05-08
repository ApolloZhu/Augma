import cv2

camera = cv2.VideoCapture(0)

while camera.isOpened():
    rect, frame = camera.read()
    print(rect)
    cv2.imshow('original', frame)

