import asyncio
import pyaudio
import yaml
import json
from pydub import AudioSegment
from pydub.silence import detect_silence
from deepgram import DeepgramClient, LiveTranscriptionEvents, LiveOptions, DeepgramClientOptions

class SpeechRecognizer:
    def __init__(self, config_file):
        with open(config_file, 'r') as file:
            self.config = yaml.safe_load(file)
        with open(config_file+"_private", 'r') as file:
            self.config_private = yaml.safe_load(file)
        self.dg_client = DeepgramClient(self.config_private['DEEPGRAM_API_KEY'], DeepgramClientOptions(options={"keepalive": "true"}))
        self.dg_connection = None
        self.audio = None
        self.stream = None
        self.sentence = []

    def create_deepgram_connection(self):
        self.dg_connection = self.dg_client.listen.live.v("1")

    def configure_deepgram(self):
        def on_transcript(self2, result, **kwargs):
            try:
                transcript = result.channel.alternatives[0].transcript
                if transcript and result.is_final:
                    print(transcript, flush=True)
            except Exception as e:
                print(f"Error in transcript callback: {e}")

        self.dg_connection.on(LiveTranscriptionEvents.Transcript, on_transcript)

        self.dg_connection.start(LiveOptions(
            model=self.config['deepgram']['model'],
            language=self.config['deepgram']['language'],
            encoding=self.config['deepgram']['encoding'],
            channels=self.config['audio']['channels'],
            sample_rate=self.config['audio']['frame_rate'],
            interim_results=False,
            endpointing=500,
        ))
      

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

    async def process_audio(self):
        print("Start speaking. Press Ctrl+C to stop.")
        try:
            while True:
                data = await asyncio.to_thread(self.stream.read, self.config['audio']['chunk_size'], exception_on_overflow=False)
                await asyncio.to_thread(self.dg_connection.send, data)
                
        except KeyboardInterrupt:
            print("Stopping...")
        except Exception as e:
            print(f"An error occurred: {e}")
        finally:
            self.stream.stop_stream()
            self.stream.close()

    def get_microphone_stream(self):
        self.audio = pyaudio.PyAudio()
        self.stream = self.setup_audio_stream()

    async def run(self):
        try:
            self.create_deepgram_connection()
            self.configure_deepgram()
            self.get_microphone_stream()
            await self.process_audio()
        finally:
            if self.audio:
                self.audio.terminate()
            # if self.dg_connection:
            #     await self.dg_connection.finish()

async def main():
    recognizer = SpeechRecognizer('config.yaml')
    await recognizer.run()

asyncio.run(main())