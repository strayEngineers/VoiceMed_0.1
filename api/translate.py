import os
import html
from google.cloud import translate_v2 as translate

def translate_text(text, target_language='en'):
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    client = translate.Client.from_service_account_json(credentials_path)

    try:
        placeholder = '$'
        text_with_placeholder = text.replace('\n', placeholder)

        translation = client.translate(text_with_placeholder, target_language=target_language)

        translated_text = html.unescape(translation['translatedText']).replace(placeholder, '\n')

        translated_text = '\n'.join(line.lstrip() for line in translated_text.split('\n'))

        translated_text = translated_text.replace('【', '[').replace('】', ']')

        print("Translated text:", translated_text)
        return translated_text

    except Exception as e:
        raise Exception(f"An error occurred during translation: {e}")
