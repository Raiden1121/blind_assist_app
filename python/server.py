import asyncio
import logging
import math
import time
import os
from typing import AsyncIterable, Iterable, Dict
import wave
import io
import uuid

import grpc
import gemini_chat_pb2
import gemini_chat_pb2_grpc
from dotenv import load_dotenv
import speech_recognition as sr
import httpx
from google import genai
from google.genai import types
import navigator
from navigator import SessionState,NavResponse

load_dotenv()

GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
logging.basicConfig(level=logging.INFO)

# Store active sessions
active_sessions: Dict[str, SessionState] = {}

def get_or_create_session(session_id: str) -> SessionState:
    if session_id not in active_sessions:
        active_sessions[session_id] = SessionState(session_id=session_id)
        logging.info(f"Created new session: {session_id}")
    return active_sessions[session_id]

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
        return "Cannot understand audio"
    except sr.RequestError as e:
        logging.error(f"Could not request results from Google Speech Recognition service; {e}")
        return None
    except Exception as e:
        logging.error(f"An error occurred during audio transcription: {e}")
        return None

class GeminiChatServicer(gemini_chat_pb2_grpc.GeminiChatServicer):

    async def CreateSession(
        self, request: gemini_chat_pb2.CreateSessionRequest, 
        context) -> gemini_chat_pb2.CreateSessionResponse:
        try:
            # Generate a unique session ID
            session_id = str(uuid.uuid4())
            
            # Create session state with provided API keys
            session_state = SessionState(
                session_id=session_id,
                gemini_api_key=request.gemini_api_key if request.HasField("gemini_api_key") else None,
                maps_api_key=request.maps_api_key if request.HasField("maps_api_key") else None
            )
            
            # Store session state
            active_sessions[session_id] = session_state
            
            logging.info(f"Created new session: {session_id}")
            return gemini_chat_pb2.CreateSessionResponse(
                session_id=session_id,
                success=True
            )
            
        except Exception as e:
            logging.error(f"Error creating session: {e}")
            return gemini_chat_pb2.CreateSessionResponse(
                session_id="",
                success=False,
                error_message=str(e)
            )

    async def ChatStream(
            self, request_iterator: AsyncIterable[gemini_chat_pb2.ChatRequest],
            context) -> AsyncIterable[gemini_chat_pb2.ChatResponse]:
        
        session_state = None
        try:
            async for request in request_iterator:
                if not request.session_id:
                    logging.error("Received request without session_id")
                    continue
                
                # Get existing session or return error
                session_state = active_sessions.get(request.session_id)
                if not session_state:
                    logging.error(f"Invalid session ID: {request.session_id}")
                    response = gemini_chat_pb2.ChatResponse()
                    response.session_id = request.session_id
                    response.nav.nav_description = "Error: Invalid session ID"
                    yield response
                    continue
                
                logging.info(f"Processing request for session {request.session_id}")
                
                if (request.HasField("location") and request.location.lat and request.location.lng):
                    lat = request.location.lat
                    lng = request.location.lng
                    logging.info(f"Session {session_state.session_id}: Received location: {lat}, {lng}")
                    navigator.set_current_location(session_state, {"lat": lat, "lng": lng})
            
                text_prompt = ""
                audio_text = ""
                llm_resp = None
                
                multi_images = []
                if request.HasField("multi_images") and len(request.multi_images.images) > 0:
                    for img in request.multi_images.images:
                        if img.data:
                            multi_images.append(img.data)
                            
                logging.info(f"Session {session_state.session_id}: Processing {len(multi_images)} images")
                if request.HasField("text"):
                    text_prompt = request.text
                    logging.info(f"Session {session_state.session_id}: Received text: {text_prompt}")
                    llm_resp = await navigator.chatbot_conversation(session_state, text_prompt,multi_images)
                elif request.HasField("audio") and request.audio.data:
                    audio_text = await asyncio.to_thread(
                        transcribe_audio, request.audio.data)
                    
                    if audio_text == "Cannot understand audio":
                        llm_resp = NavResponse(response_text="Please repeat your request.",alerts=[])
                        logging.warning(f"Session {session_state.session_id}: Cannot understand audio")
                    elif audio_text:
                        llm_resp = await navigator.chatbot_conversation(session_state, audio_text,multi_images)
                        logging.info(f"Session {session_state.session_id}: Transcribed audio: {audio_text}")
                    else:
                        logging.error(f"Session {session_state.session_id}: Failed to transcribe audio")
                
                    # logging.info(f"Session {session_state.session_id}: Processing {len(multi_images)} images")
                    # alert_resp = await navigator.chatbot_conversation(session_state, 
                    #     navigator.images_alert_prompt, multi_images)

                response = gemini_chat_pb2.ChatResponse()
                response.session_id = request.session_id
                
                response.nav.nav_status = session_state.status == "Navigating"
                if llm_resp:
                    response.nav.nav_description = llm_resp.response_text
                else:
                    response.nav.nav_description = ""
                
                yield response

        except Exception as e:
            logging.error(f"Error in ChatStream: {e}")
            if session_state:
                logging.error(f"Error occurred for session {session_state.session_id}")
            raise

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