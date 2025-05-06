import tensorflow as tf

# Load model keras
model = tf.keras.models.load_model("models/bola_detector.keras")

# Konversi ke tflite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Simpan ke file .tflite
with open("models/bola_detector.tflite", "wb") as f:
    f.write(tflite_model)
