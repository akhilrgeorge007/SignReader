import tensorflow as tf
from tensorflow import lite

model = tf.keras.models.load_model('Model\keras_model.h5')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
open('Model\keras_model.tflite', 'wb').write(tflite_model)
