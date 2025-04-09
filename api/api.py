import os
from dotenv import load_dotenv
from flask import Flask, jsonify, request, send_from_directory
from image_recognition import recognize_text
from image_recognition import recognize_check_box
from image_recognition import crop_image
from tts import text_to_speech
from translate import translate_text

load_dotenv('env-config/.env')

api = Flask(__name__)

audio_folder = os.path.join(os.getcwd(), "audio_files")
os.makedirs(audio_folder, exist_ok=True)

@api.route("/", methods=["POST"])
def endpoint():
    text = None
    checkbox = []
    cropped_image_file = None

    output_file_zh = os.path.join(audio_folder, "output_zh-TW.mp3")
    output_file_en = os.path.join(audio_folder, "output_en.mp3")

    if 'image' in request.files:
        file = request.files['image']
        image_data = file.read()

        # 將 OpenCV 輪廓偵測結果的圖像傳給文字辨識函數
        try:
            cropped_image_file = crop_image(image_data)
        except Exception as e:
            return jsonify({"error": str(e)}), 400 

        text = recognize_text(cropped_image_file)
        checkbox = recognize_check_box(cropped_image_file)
        if not text:
            return jsonify({"error": "Text not recognized from image"}), 400
    elif 'text' in request.form:
        text = request.form['text']
    else:
        return jsonify({"error": "No image or text provided"}), 400
    
    try:
        translated_text = translate_text(text, target_language='en')
    except Exception as e:
        return jsonify({"error": f"Translation failed: {str(e)}"}), 500

    try:
        text_to_speech(text, output_file_zh, language='zh-TW')
        text_to_speech(translated_text, output_file_en, language='en')
    except Exception as e:
        return jsonify({"error": f"Text-to-speech conversion failed: {str(e)}"}), 500

    response_data = {
        "text": text,
        "translated_text": translated_text,
        "checkbox": checkbox,
        "audio_files": {
            "zh": f"http://{request.host}/tts?file={os.path.basename(output_file_zh)}",
            "en": f"http://{request.host}/tts?file={os.path.basename(output_file_en)}"
        }
    }
    return jsonify(response_data)

@api.route("/tts", methods=["GET"])
def serve_audio():
    file_name = request.args.get('file')
    
    return send_from_directory(audio_folder, file_name)

if __name__ == "__main__":
    api.run(host="192.168.17.253", port=8080, debug=True)
