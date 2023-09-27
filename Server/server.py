from flask import Flask, request, jsonify
import cv2
from flask_cors import CORS
from cvzone.HandTrackingModule import HandDetector
from cvzone.ClassificationModule import Classifier
import numpy as np
import math

app = Flask(__name__)
CORS(app)

cap = cv2.VideoCapture(0)
detector = HandDetector(maxHands=1)
classifier = Classifier("Model/keras_model.h5", "Model/labels.txt")

offset = 20
imgSize = 300

labels = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Space"]

@app.route('/predict', methods=['POST'])
def predict():
    # Read the image from the form data
    image_file = request.files['image']
    image = cv2.imdecode(np.fromstring(image_file.read(), np.uint8), cv2.IMREAD_COLOR)
    
    imgOutput = image.copy()
    hands, img = detector.findHands(image)
    
    if hands:
        hand = hands[0]
        x, y, w, h = hand['bbox']
        
        imgWhite = np.ones((imgSize, imgSize, 3), np.uint8)*255
        imgCrop = img[y-offset:y+h+offset, x-offset:x+w+offset]
        
        imgCropShape = imgCrop.shape
        
        aspectRatio = h / w
        
        if aspectRatio > 1:
            k = imgSize / h
            wCal = math.ceil(k * w)
            imgResize = cv2.resize(imgCrop, (wCal, imgSize))
            imgResizeShape = imgResize.shape
            wGap = math.ceil((imgSize-wCal)/2)
            imgWhite[:, wGap:wCal+wGap] = imgResize
            prediction, index = classifier.getPrediction(imgWhite, draw=False)
        else:
            k = imgSize / w
            hCal = math.ceil(k * h)
            imgResize = cv2.resize(imgCrop, (imgSize, hCal))
            imgResizeShape = imgResize.shape
            hGap = math.ceil((imgSize - hCal) / 2)
            imgWhite[hGap:hCal + hGap, :] = imgResize
            prediction, index = classifier.getPrediction(imgWhite, draw=False)
            print(prediction)
        label = labels[index]
        
        cv2.rectangle(imgOutput, (x - offset, y - offset-50), (x-offset+90, y-offset), (255, 0, 255), cv2.FILLED)
        cv2.putText(imgOutput, label, (x, y-26), cv2.FONT_HERSHEY_COMPLEX, 1.7, (255, 255, 255), 2)
        cv2.rectangle(imgOutput, (x-offset, y-offset), (x+w+offset, y+h+offset), (255, 0, 255), 4)
        
        cv2.imwrite('output.jpg', imgWhite)  # Save the output image for testing purposes
        
        return jsonify({'label': label})
    
    return jsonify({'error': 'No hands detected'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=False)