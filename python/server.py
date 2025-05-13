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
from tool_schemas import (
    geocode_decl,
    route_decl,
    reverse_geocode_decl,
    search_places_decl,
    place_details_decl  # Add this
)
from function_calling import (
    geocode_place,
    compute_route,
    reverse_geocode,
    search_places,
    place_details
)

load_dotenv()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")
GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
logging.basicConfig(level=logging.INFO)

system_instruction = """
You are a digital assistant specifically designed for visually impaired users, equipped with powerful navigation capabilities.

You should use navigation tools for the following types of requests:
1. Explicit navigation requests: e.g., "take me to XXX", "how to get to XXX", "go to XXX"
2. Phrases containing directional words: e.g., "walk to", "go over to", "get to"
3. Questions about locations or routes: e.g., "where is XXX", "how to reach XXX"

During navigation, you should:
- First use geocode_place to find the destination location
- Then use compute_route to calculate the route
- Finally, convert route instructions into visually impaired-friendly descriptions

For non-navigation general questions, respond directly without using tool functions.

Important: When users mention "my current location" or "I'm here", you should use geocode_place with the query parameter set to "CURRENT_LOCATION".
"""

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))  # v1.x client

routes_tool = [types.Tool(function_declarations=[
    route_decl,
    geocode_decl,
    reverse_geocode_decl,
    search_places_decl,
    place_details_decl  # Add this
])]

config = {
    "tools": routes_tool,  # FunctionCall schema
    "automatic_function_calling": {
        "disable": True
    },
    # "tool_config": {
    #     "function_calling_config": {
    #         "mode": "any"
    #     }
    # },
    "system_instruction": system_instruction
}

chat = client.chats.create(model="gemini-1.5-pro", config=config)

async def ask_llm(message, image_bytes=None):
    """
    Handles LLM interaction with function calling support

    Args:
        message: str | types.Content | types.FunctionResponse | types.Part
            - str: Direct user input
            - types.Content: Structured content from previous response
            - types.FunctionResponse: Result from tool function call
            - types.Part: Individual message part

    Returns:
        tuple[list[dict] | None, str]:
            - First element: Route steps if navigation, else None
            - Second element: Text response from LLM
    """
    print(f"Sending to model: {type(message)}",
          message if isinstance(message, str) else "Function response")

    # Handle different message types
    if isinstance(message, types.Content):
        parts = message.parts
        resp = chat.send_message(parts[0] if parts else "Empty content")
    elif isinstance(message, types.FunctionResponse):
        resp = chat.send_message(types.Part(function_response=message))
    elif isinstance(message, types.Part):
        resp = chat.send_message(message)
    elif isinstance(message, str):
        resp = chat.send_message(types.Part(text=message))
    else:
        # if (image_bytes is not None):
        #     parts = [
        #         types.Part(text=message),
        #         types.Part(inline_data={"mime_type": "image/jpeg", "data": image_bytes})
        #     ]
        #     resp = chat.send_message(parts)
        # else:
            resp = chat.send_message(message)
        

    if not resp.candidates:
        print("No candidates in response")
        return None, "No response from model"

    part = resp.candidates[0].content.parts[0]

    # Handle function calls
    if hasattr(part, 'function_call') and part.function_call:
        fn = part.function_call
        print(f"Function call detected: {fn.name}")

        try:
            if fn.name == "geocode_place":
                geo = await geocode_place(**fn.args)
                fn_resp = types.FunctionResponse(
                    name="geocode_place",
                    response=geo
                )
                return await ask_llm(fn_resp)

            elif fn.name == "reverse_geocode":
                address = await reverse_geocode(**fn.args)
                fn_resp = types.FunctionResponse(
                    name="reverse_geocode",
                    response=address
                )
                return await ask_llm(fn_resp)

            elif fn.name == "compute_route":
                steps = await compute_route(**fn.args)
                fn_resp = types.FunctionResponse(
                    name="compute_route",
                    response={"steps": steps}
                )
                nav = chat.send_message(types.Part(function_response=fn_resp))

                if nav.candidates and nav.candidates[0].content.parts:
                    text_parts = [p.text for p in nav.candidates[0].content.parts
                                  if hasattr(p, 'text') and p.text]
                    nav_text = " ".join(
                        text_parts) if text_parts else "No text in response"
                else:
                    nav_text = "No response text available"
                return steps, nav_text

            elif fn.name == "search_places":
                places = await search_places(**fn.args)
                fn_resp = types.FunctionResponse(
                    name="search_places",
                    response={"places": places}
                )
                return await ask_llm(fn_resp)

            # Add in the function handling section of ask_llm
            elif fn.name == "place_details":
                try:
                    details = await place_details(**fn.args)
                    fn_resp = types.FunctionResponse(
                        name="place_details",
                        response=details
                    )
                    return await ask_llm(fn_resp)
                except Exception as e:
                    print(f"Error getting place details: {e}")
                    return None, f"Error getting place details: {str(e)}"
        except Exception as e:
            print(f"Error in {fn.name}: {e}")
            return None, f"Error executing {fn.name}: {str(e)}"

    # Handle text responses
    if hasattr(part, 'text') and part.text:
        return None, part.text

    # Try to extract text from parts
    if hasattr(resp.candidates[0].content, 'parts'):
        text_parts = [p.text for p in resp.candidates[0].content.parts
                      if hasattr(p, 'text') and p.text]
        if text_parts:
            return None, " ".join(text_parts)

    # Fallback to string conversion
    try:
        return None, str(resp)
    except:
        return None, "Could not extract text from response"

def transcribe_audio(audio_bytes):
    recognizer = sr.Recognizer()
    
    try:
        # if the audio_bytes is a WAV file, we need to convert it to PCM raw data
        if audio_bytes.startswith(b'RIFF') and b'WAVE' in audio_bytes[:12]:
            logging.info("Detected WAV file format")
            
            # use io.BytesIO to read the WAV file
            with io.BytesIO(audio_bytes) as wav_io:
                with wave.open(wav_io, 'rb') as wav_file:
                    # get WAV file properties
                    channels = wav_file.getnchannels()
                    sample_width = wav_file.getsampwidth()
                    wav_sample_rate = wav_file.getframerate()
                    
                    # read the PCM data
                    pcm_data = wav_file.readframes(wav_file.getnframes())
                    
                    audio_bytes = pcm_data
                    logging.info(f"Converted WAV to PCM raw data with sample rate {wav_sample_rate}")
        else:
            logging.info("Detected raw PCM audio format")
        audio_data = sr.AudioData(audio_bytes, wav_sample_rate, 2)  # each sample is 2 bytes (16 bits)
        
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

        # Process incoming requests
        async for request in request_iterator:
            logging.info(f"Received request: {request.request_id}")
            
            if (request.HasField("audio") and request.audio.data):
                audio_text = await asyncio.to_thread(
                    transcribe_audio, request.audio.data)
                
                if audio_text:
                    logging.info(f"Transcribed audio text: {audio_text}")
                else:
                    logging.error("Failed to transcribe audio")
            
            steps, llm_resp = await ask_llm(audio_text)
            
            # Here you would typically process the request and generate a response
            response = gemini_chat_pb2.ChatResponse()
            response.nav.alert = "Processing your request..."
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
