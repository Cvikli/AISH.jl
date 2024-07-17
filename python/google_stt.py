# transcribe_streaming("hu-HU")

import asyncio
import pyaudio
import yaml
from google.cloud import speech_v1p1beta1 as speech

import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "diabtrend-db-8213ca3be14e.json"


class SpeechRecognizer:
    def __init__(self, config_file):
        with open(config_file, 'r') as file:
            self.config = yaml.safe_load(file)
        with open(config_file+"_private", 'r') as file:
            self.config_private = yaml.safe_load(file)
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = config["google_credentials_path"]
        self.client = speech.SpeechClient()
        self.audio = None
        self.stream = None

    def list_input_devices(self):
        info = self.audio.get_host_api_info_by_index(0)
        numdevices = info.get('deviceCount')
        print("Input Device ids:")
        for i in range(0, numdevices):
            if (self.audio.get_device_info_by_host_api_device_index(0, i).get('maxInputChannels')) > 0:
                print(i, " - ", self.audio.get_device_info_by_host_api_device_index(0, i).get('name'))

    def select_input_device(self):
        self.list_input_devices()
        return int(input("Enter the ID of the input device you want to use: "))

    def setup_audio_stream(self):
        device_id = self.config['audio'].get('device_id', 4)
        if device_id == -1:
            device_id = self.select_input_device()
        
        return self.audio.open(
            format=pyaudio.paInt16,
            channels=self.config['audio']['channels'],
            rate=self.config['audio']['frame_rate'],
            input=True,
            input_device_index=device_id,
            frames_per_buffer=self.config['audio']['chunk_size']
        )

    def get_microphone_stream(self):
        self.audio = pyaudio.PyAudio()
        self.stream = self.setup_audio_stream()

    def audio_generator(self):
        while True:
            chunk = self.stream.read(self.config['audio']['chunk_size'], exception_on_overflow=False)
            yield speech.StreamingRecognizeRequest(audio_content=chunk)

    async def process_audio(self):
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
            sample_rate_hertz=self.config['audio']['frame_rate'],
            language_code=self.config['google']['language'],
            model=self.config['google']['model'],
        )
        streaming_config = speech.StreamingRecognitionConfig(
            config=config, interim_results=True
        )

        print("Start speaking. Press Ctrl+C to stop.")
        try:
            requests = self.audio_generator()
            responses = self.client.streaming_recognize(streaming_config, requests)

            for response in responses:
                for result in response.results:
                    if result.is_final:
                        print(result.alternatives[0].transcript)
                    
        except KeyboardInterrupt:
            print("Stopping...")
        except Exception as e:
            print(f"An error occurred: {e}")
        finally:
            self.stream.stop_stream()
            self.stream.close()

    async def run(self):
        try:
            self.get_microphone_stream()
            await self.process_audio()
        finally:
            if self.audio:
                self.audio.terminate()

async def main():
    recognizer = SpeechRecognizer('config.yaml')
    await recognizer.run()

asyncio.run(main())