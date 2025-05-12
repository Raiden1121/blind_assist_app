import asyncio
import grpc
import os
import time
import traceback
import logging # Added for logging

# Import your generated protobuf files
try:
    import blind_assist_pb2
    import blind_assist_pb2_grpc
except ImportError:
    print("Error: Could not import generated protobuf files.")
    print("Ensure blind_assist_pb2.py and blind_assist_pb2_grpc.py are in the Python path.")
    exit(1)

SERVER_ADDRESS = 'localhost:50051'
CLIENT_ID = "async_client_01"

# --- Dummy File Setup ---
# (Include create_dummy_files() function and paths as in the previous client)
DUMMY_IMAGE_PATH = "dummy_image.jpg"
DUMMY_AUDIO_PATH = "dummy_audio.raw"
DUMMY_AUDIO_MIME = "audio/L16; rate=16000; channels=1"
DUMMY_AUDIO_SAMPLE_RATE = 16000
DUMMY_IMAGE_MIME = "image/jpeg"

def create_dummy_files():
    # (Same implementation as before to create dummy files)
    if not os.path.exists(DUMMY_AUDIO_PATH):
        print(f"Creating dummy audio file: {DUMMY_AUDIO_PATH}")
        try:
            sample_rate = 16000; duration_sec = 1; bytes_per_sample = 2
            num_samples = sample_rate * duration_sec
            with open(DUMMY_AUDIO_PATH, "wb") as f: f.write(b'\x00' * (num_samples * bytes_per_sample))
        except Exception as e: print(f"  Error creating dummy audio file: {e}")

    if not os.path.exists(DUMMY_IMAGE_PATH):
         print(f"Creating dummy image file: {DUMMY_IMAGE_PATH}")
         try:
            import base64
            jpeg_data = base64.b64decode("/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8+P8AgpD/AMFLf20vgX/wUW/ak+EXwo/ax+Ofw9+Gvw8+O/xC8MeDvB3g/wCJfibQPDfhfQNK8V6rp+l6Lo2j6ZqVtYaZpWnWUEFnYWFlbxW1paxRwwRJGqqoAP/Z")
            with open(DUMMY_IMAGE_PATH, "wb") as f: f.write(jpeg_data)
         except Exception as e: print(f"  Error creating dummy image file: {e}")


# --- Async Generator for Client Requests ---
# Equivalent to RouteGuide's generate_messages but async and using your protos
async def generate_requests():
    """Async generator for client requests for ChatStream."""

    # 1. Initial Configuration (Unique to your service)
    logging.info(f"[{CLIENT_ID}] Sending Initial Configuration...")
    config_req = blind_assist_pb2.ClientRequest(
        initial_config=blind_assist_pb2.InitialConfig(
            model_name="models/gemini-2.0-flash-live-001", # Example
            response_modalities=["AUDIO", "TEXT"]
        )
    )
    yield config_req
    await asyncio.sleep(0.1)

    # 2. Send Text
    logging.info(f"[{CLIENT_ID}] Sending Text...")
    text_req = blind_assist_pb2.ClientRequest(
        text_part=blind_assist_pb2.TextPart(text="Describe this scene.")
    )
    yield text_req
    await asyncio.sleep(0.2)

    # 3. Send Image (Example)
    if os.path.exists(DUMMY_IMAGE_PATH):
        logging.info(f"[{CLIENT_ID}] Sending Image ({DUMMY_IMAGE_PATH})...")
        try:
            with open(DUMMY_IMAGE_PATH, "rb") as f: image_data = f.read()
            image_req = blind_assist_pb2.ClientRequest(
                image_part=blind_assist_pb2.ImagePart(image_data=image_data, mime_type=DUMMY_IMAGE_MIME)
            )
            yield image_req
            await asyncio.sleep(0.2)
        except Exception as e: logging.error(f"[{CLIENT_ID}] Error reading/sending image: {e}")
    else: logging.warning(f"[{CLIENT_ID}] Dummy image not found: {DUMMY_IMAGE_PATH}")

    # 4. Send Audio (Example)
    if os.path.exists(DUMMY_AUDIO_PATH):
        logging.info(f"[{CLIENT_ID}] Sending Audio ({DUMMY_AUDIO_PATH})...")
        try:
             with open(DUMMY_AUDIO_PATH, "rb") as f: audio_data = f.read()
             audio_req = blind_assist_pb2.ClientRequest(
                 client_audio_part=blind_assist_pb2.ClientAudioPart(
                     audio_data=audio_data, # Send as one chunk here for simplicity
                     mime_type=DUMMY_AUDIO_MIME,
                     sample_rate=DUMMY_AUDIO_SAMPLE_RATE
                 )
             )
             yield audio_req
             await asyncio.sleep(0.2)
        except Exception as e: logging.error(f"[{CLIENT_ID}] Error reading/sending audio: {e}")
    else: logging.warning(f"[{CLIENT_ID}] Dummy audio not found: {DUMMY_AUDIO_PATH}")

    # 5. End Turn (Unique to your service logic)
    logging.info(f"[{CLIENT_ID}] Sending End of Turn...")
    yield blind_assist_pb2.ClientRequest(end_of_turn=True)
    await asyncio.sleep(0.1)

    logging.info(f"[{CLIENT_ID}] Finished sending requests.")


# --- Main Async Function ---
# Equivalent to RouteGuide's run() but adapted for async and ChatStream
async def run_chat_stream():
    """Connects and runs the async bidirectional ChatStream test."""
    create_dummy_files() # Make sure dummy files exist

    # Use grpc.aio.insecure_channel
    async with grpc.aio.insecure_channel(SERVER_ADDRESS) as channel:
        # Create the async stub
        stub = blind_assist_pb2_grpc.GeminiLiveStub(channel)
        logging.info(f"--- Starting ChatStream (Client ID: {CLIENT_ID}) ---")

        try:
            # Call the bidirectional streaming RPC, passing the async generator
            response_iterator = stub.ChatStream(generate_requests())
            # Asynchronously iterate through server responses
            logging.info(f"[{CLIENT_ID}] Waiting for server responses...")
            async for response in response_iterator:
                print(response)
                # Process different parts of the ServerResponse message
                if response.HasField("text_part"):
                    logging.info(f"[Server Response] Text: {response.text_part.text}")
                elif response.HasField("gemini_audio_part"):
                    audio_info = response.gemini_audio_part
                    logging.info(f"[Server Response] Audio Chunk:"
                          f" Size={len(audio_info.audio_data)} bytes,"
                          f" Mime={audio_info.mime_type},"
                          f" Rate={audio_info.sample_rate}")
                elif response.HasField("error_part"):
                    logging.error(f"[Server Response] Error: {response.error_part.message}")
                elif response.turn_complete:
                    logging.info("[Server Response] Turn Complete Signal Received.")
                else:
                    logging.warning("[Server Response] Received empty/unknown message.")

        except grpc.aio.AioRpcError as e:
            # Handle potential gRPC communication errors
            logging.error(f"\n!!! gRPC Error !!! Code: {e.code()} Details: {e.details()}")
        except Exception as e:
            # Handle other unexpected errors
            logging.error(f"\n!!! An unexpected error occurred: {e}")
            traceback.print_exc()
        finally:
            logging.info(f"--- ChatStream Finished (Client ID: {CLIENT_ID}) ---")


# --- Entry Point ---
if __name__ == '__main__':
    # Basic logging configuration
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    # Handle Windows asyncio policy if needed
    if os.name == 'nt':
       logging.info("Applying WindowsSelectorEventLoopPolicy for asyncio.")
       asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    logging.info("Starting Async gRPC Client...")
    try:
        # Run the main async function
        asyncio.run(run_chat_stream())
    except KeyboardInterrupt:
        logging.info("\nClient interrupted by user.")
    except Exception as e:
        logging.critical(f"Unhandled exception in main execution: {e}")
        traceback.print_exc()
    finally:
        logging.info("Async gRPC Client finished.")