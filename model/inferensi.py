import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing import image
import matplotlib.pyplot as plt

# Load TFLite model dengan interpreter
interpreter = tf.lite.Interpreter(model_path='models/bola_detector.tflite')
interpreter.allocate_tensors()

# Ambil input & output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Class names sesuai urutan saat training
class_names = ['basketball', 'football', 'no_ball', 'volleyball']

# Load dan preprocess gambar
img_path = 'test_real/4.jpeg'
img = image.load_img(img_path, target_size=(224, 224))
img_array = image.img_to_array(img)
img_array = np.expand_dims(img_array, axis=0)
img_array = img_array.astype(np.float32)  # pastikan tipe data cocok

# (Opsional) Normalisasi jika model waktu training dinormalisasi
img_array /= 255.0  # hanya jika model dilatih pakai normalize

# Set input tensor
interpreter.set_tensor(input_details[0]['index'], img_array)

# Jalankan inferensi
interpreter.invoke()

# Ambil hasil output
output_data = interpreter.get_tensor(output_details[0]['index'])
pred_label = class_names[np.argmax(output_data)]

# Tampilkan hasil prediksi
print(f'Prediksi Gambar: {pred_label}')

# Tampilkan gambar
plt.imshow(img)
plt.title(f'Prediksi: {pred_label}')
plt.axis('off')
plt.show()
