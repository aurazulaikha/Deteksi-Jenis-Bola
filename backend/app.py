from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from PIL import Image
import io
import datetime
import mysql.connector
from werkzeug.utils import secure_filename
import os

app = Flask(__name__)

# Konfigurasi koneksi database
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  
    'database': 'ball_tect'
}

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path="models/bola_detector.tflite")
interpreter.allocate_tensors()

# Dapatkan detail input/output
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Label
label_mapping = ['basketball', 'football', 'no_ball', 'volleyball']

# Folder untuk simpan gambar
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Fungsi preprocessing
def preprocess(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((224, 224))
    img_array = np.array(img).astype(np.float32) / 255.0
    return img_array

# Simpan hasil ke database tanpa akurasi
def simpan_ke_database(jenis_bola, waktu_deteksi, filename):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        query = """
            INSERT INTO riwayat_deteksi (jenis_bola, waktu_deteksi, filename)
            VALUES (%s, %s, %s)
        """
        values = (jenis_bola, waktu_deteksi, filename)
        cursor.execute(query, values)
        conn.commit()
        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        print("Error MySQL:", err)

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']

    if file and file.filename.lower().endswith(('png', 'jpg', 'jpeg')):
        filename = secure_filename(file.filename)
        save_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(save_path)

        # Preprocessing
        with open(save_path, 'rb') as img_file:
            img_array = preprocess(img_file.read())
        input_data = np.expand_dims(img_array, axis=0)

        # Prediksi pakai TFLite
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        prediction = interpreter.get_tensor(output_details[0]['index'])

        label_idx = int(np.argmax(prediction))
        waktu = datetime.datetime.now()

        # Simpan ke database tanpa akurasi
        simpan_ke_database(label_mapping[label_idx], waktu, filename)

        dummy_detection = {
            'label': label_mapping[label_idx],
            'bounds': {
                'left': 50,
                'top': 50,
                'right': 200,
                'bottom': 200
            }
        }

        return jsonify({
            'jenis_bola': label_mapping[label_idx],
            'waktu': waktu.isoformat(),
            'filename': filename,
            'detections': [dummy_detection]
        })
    else:
        return jsonify({'error': 'Invalid file format. Only PNG, JPG, and JPEG allowed.'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
