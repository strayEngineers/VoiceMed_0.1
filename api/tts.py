import os
from google.cloud import texttospeech

def text_to_speech(text, output_file_path, language='zh-TW'):
    
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    client = texttospeech.TextToSpeechClient.from_service_account_json(credentials_path)

    input_text = texttospeech.SynthesisInput(text=text)

    voice = texttospeech.VoiceSelectionParams(
        language_code=language,
        ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
    )

    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3
    )

    try:
        response = client.synthesize_speech(
            request={"input": input_text, "voice": voice, "audio_config": audio_config}
        )

        with open(output_file_path, "wb") as out:
            out.write(response.audio_content)
            print(f'Audio content written to file "{output_file_path}"')

    except Exception as e:
        print(f"An error occurred: {e}")

