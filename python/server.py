import asyncio
import logging
import math
import time
import os
from typing import AsyncIterable, Iterable
import wave
import io

import grpc
import gemini_chat_pb2
import gemini_chat_pb2_grpc
from dotenv import load_dotenv

import speech_recognition as sr

import httpx
from google import genai  # v1.x import path
from google.genai import types  # FunctionCall / Content
import function_calling

load_dotenv()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")
GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
logging.basicConfig(level=logging.INFO)

image_alert_prompt = "Analyze this image for hazards or obstacles and output a concise alert stating the risk and recommended action."
images_alert_prompt = "Analyze these walking-scene images for hazards or obstacles and for each image output a brief alert with the risk and recommended action."

def transcribe_audio(audio_bytes):
    recognizer = sr.Recognizer()
    
    try:
        sample_rate = 16000 # default sample rate for Google Speech Recognition
        # if the audio_bytes is a WAV file, we need to convert it to PCM raw data
        if audio_bytes.startswith(b'RIFF') and b'WAVE' in audio_bytes[:12]:
            logging.info("Detected WAV file format")
            
            # use io.BytesIO to read the WAV file
            with io.BytesIO(audio_bytes) as wav_io:
                with wave.open(wav_io, 'rb') as wav_file:
                    # get WAV file properties
                    channels = wav_file.getnchannels()
                    sample_width = wav_file.getsampwidth()
                    sample_rate = wav_file.getframerate()
                    
                    # read the PCM data
                    pcm_data = wav_file.readframes(wav_file.getnframes())
                    
                    audio_bytes = pcm_data
                    logging.info(f"Converted WAV to PCM raw data with sample rate {sample_rate}")
        else:
            logging.info("Detected raw PCM audio format")
        audio_data = sr.AudioData(audio_bytes, sample_rate, 2)  # each sample is 2 bytes (16 bits)
        
        text = recognizer.recognize_google(audio_data)
        logging.info(f"Transcribed text: {text}")
        return text
    except sr.UnknownValueError:
        logging.warning("Google Speech Recognition could not understand audio")
        return None
    except sr.RequestError as e:
        logging.error(f"Could not request results from Google Speech Recognition service; {e}")
        return None
    except Exception as e:
        logging.error(f"An error occurred during audio transcription: {e}")
        return None

class GeminiChatServicer(gemini_chat_pb2_grpc.GeminiChatServicer):

    async def ChatStream(
            self, request_iterator: AsyncIterable[gemini_chat_pb2.ChatRequest],
            context) -> AsyncIterable[gemini_chat_pb2.ChatResponse]:
        """雙向串流：客戶端可以流式送多筆 audio/image 訊息，後端流式回應
        """
        logging.info("ChatStream called")
        
        audio_text = ""
        llm_resp = None
        steps = None
        
        # Process incoming requests
        async for request in request_iterator:
            logging.info(f"Received request: ")
            
            if (request.HasField("audio") and request.audio.data):
                audio_text = await asyncio.to_thread(
                    transcribe_audio, request.audio.data)
                
                if audio_text:
                    logging.info(f"Transcribed audio text: {audio_text}")
                else:
                    logging.error("Failed to transcribe audio")
            
            if (request.HasField("location") and request.location.lat and request.location.lng):
                lat = request.location.lat
                lng = request.location.lng
                logging.info(f"Received location: {lat}, {lng}")
                
                function_calling.set_current_location({"lat": lat, "lng": lng})
            
            
            if request.HasField("multi_images"):
                multi_images = []
                for img in request.multi_images.images:
                    if img.data:
                        multi_images.append(img.data)
            
                logging.info(f"Received multiple images: {len(multi_images)} images")
            
                llm_resp = await function_calling.chatbot_conversation(audio_text)
                alert_resp = await function_calling.chatbot_conversation(images_alert_prompt, multi_images)
            else:
                llm_resp = await function_calling.chatbot_conversation(audio_text)
                logging.info(f"Received text: {llm_resp}")
            # Here you would typically process the request and generate a response
            response = gemini_chat_pb2.ChatResponse()
            response.nav.alert = alert_resp
            if (steps is not None):
                response.nav.nav_status = True
                response.nav.nav_description = "Navigation instructions generated."
            response.nav.nav_status = False
            response.nav.nav_description = llm_resp
            
            yield response

async def serve() -> None:
    try:
        server = grpc.aio.server()
        gemini_chat_pb2_grpc.add_GeminiChatServicer_to_server(
            GeminiChatServicer(), server)
        server.add_insecure_port('[::]:50051')
        logging.info("Starting server on port 50051...")
        await server.start()
        logging.info("Server started.")
        await server.wait_for_termination()
    except KeyboardInterrupt:
        logging.info("Server stopped by user.")
        await server.stop(0)
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        await server.stop(0)


if __name__ == "__main__":
    try:
        asyncio.run(serve())
    except KeyboardInterrupt:
        logging.info("Server stopped by user.")