import asyncio
import grpc
import os
import time
import traceback

# Import generated gRPC files (make sure they are accessible)
try:
    import blind_assist_pb2
    import blind_assist_pb2_grpc
except ImportError:
    print("Error: Could not import generated protobuf files.")
    print("Ensure blind_assist_pb2.py and blind_assist_pb2_grpc.py are in the Python path.")
    exit(1)

SERVER_ADDRESS = 'localhost:50051'
CLIENT_ID = "test_client_01" # Optional identifier

# Paths to dummy files
DUMMY_IMAGE_PATH = "dummy_image.jpg"
DUMMY_AUDIO_PATH = "dummy_audio.raw"
DUMMY_AUDIO_MIME = "audio/L16; rate=16000; channels=1" # Example MIME for raw PCM
DUMMY_AUDIO_SAMPLE_RATE = 16000 # Must match MIME if specified
DUMMY_IMAGE_MIME = "image/jpeg"

# --- Helper Functions ---

def create_dummy_files():
    """Creates dummy files if they don't exist."""
    if not os.path.exists(DUMMY_AUDIO_PATH):
        print(f"Creating dummy audio file: {DUMMY_AUDIO_PATH}")
        try:
            # Create a dummy raw audio file (e.g., 1 second of 16kHz 16-bit mono)
            sample_rate = 16000
            duration_sec = 1
            bytes_per_sample = 2 # 16-bit
            num_samples = sample_rate * duration_sec
            with open(DUMMY_AUDIO_PATH, "wb") as f:
                f.write(b'\x00' * (num_samples * bytes_per_sample)) # Silence
        except Exception as e:
            print(f"  Error creating dummy audio file: {e}")

    if not os.path.exists(DUMMY_IMAGE_PATH):
         print(f"Creating dummy image file: {DUMMY_IMAGE_PATH}")
         try:
            # Create a minimal 1x1 black pixel jpeg (base64): /9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8+P8AgpD/AMFLf20vgX/wUW/ak+EXwo/ax+Ofw9+Gvw8+O/xC8MeDvB3g/wCJfibQPDfhfQNK8V6rp+l6Lo2j6ZqVtYaZpWnWUEFnYWFlbxW1paxRwwRJGqqoAP/Z
            import base64
            jpeg_data = base64.b64decode("/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8+P8AgpD/AMFLf20vgX/wUW/ak+EXwo/ax+Ofw9+Gvw8+O/xC8MeDvB3g/wCJfibQPDfhfQNK8V6rp+l6Lo2j6ZqVtYaZpWnWUEFnYWFlbxW1paxRwwRJGqqoAP/Z")
            with open(DUMMY_IMAGE_PATH, "wb") as f:
                f.write(jpeg_data)
         except Exception as e:
             print(f"  Error creating dummy image file: {e}")


async def generate_requests():
    """Async generator for client requests."""

    # 1. Initial Configuration
    print(f"[Client {CLIENT_ID}] Sending Initial Configuration...")
    config_req = blind_assist_pb2.ClientRequest(
        initial_config=blind_assist_pb2.InitialConfig(
            model_name="models/gemini-2.0-flash-live-001", # Or leave empty for server default
            response_modalities=["AUDIO", "TEXT"] # Request both
        )
    )
    yield config_req
    await asyncio.sleep(0.1) # Small delay

    # 2. Send Text
    print(f"[Client {CLIENT_ID}] Sending Text...")
    text_req = blind_assist_pb2.ClientRequest(
        text_part=blind_assist_pb2.TextPart(text="Hello Gemini, describe what you see.")
    )
    yield text_req
    await asyncio.sleep(0.5) # Simulate thinking time before ending turn

    # 3. End Turn 1
    print(f"[Client {CLIENT_ID}] Sending End of Turn 1...")
    yield blind_assist_pb2.ClientRequest(end_of_turn=True)
    await asyncio.sleep(2) # Wait a bit for Gemini's response

    # 4. Send Image
    if os.path.exists(DUMMY_IMAGE_PATH):
        print(f"[Client {CLIENT_ID}] Sending Image ({DUMMY_IMAGE_PATH})...")
        try:
            with open(DUMMY_IMAGE_PATH, "rb") as f:
                image_data = f.read()
            image_req = blind_assist_pb2.ClientRequest(
                image_part=blind_assist_pb2.ImagePart(
                    image_data=image_data,
                    mime_type=DUMMY_IMAGE_MIME
                )
            )
            yield image_req
            await asyncio.sleep(0.2)
        except Exception as e:
            print(f"[Client {CLIENT_ID}] Error reading/sending image: {e}")
    else:
        print(f"[Client {CLIENT_ID}] Dummy image file not found: {DUMMY_IMAGE_PATH}, skipping image send.")


    # 5. Send Audio
    if os.path.exists(DUMMY_AUDIO_PATH):
        print(f"[Client {CLIENT_ID}] Sending Audio ({DUMMY_AUDIO_PATH})...")
        try:
             with open(DUMMY_AUDIO_PATH, "rb") as f:
                audio_data = f.read()
             # Simulate streaming audio in chunks (optional, could send all at once)
             chunk_size = 4096 # Send in 4KB chunks
             for i in range(0, len(audio_data), chunk_size):
                 chunk = audio_data[i:i+chunk_size]
                 print(f"[Client {CLIENT_ID}] Sending audio chunk {i//chunk_size + 1}...")
                 audio_req = blind_assist_pb2.ClientRequest(
                     client_audio_part=blind_assist_pb2.ClientAudioPart(
                         audio_data=chunk,
                         mime_type=DUMMY_AUDIO_MIME,
                         sample_rate=DUMMY_AUDIO_SAMPLE_RATE # Good practice to include
                     )
                 )
                 yield audio_req
                 await asyncio.sleep(0.05) # Simulate time between chunks
        except Exception as e:
            print(f"[Client {CLIENT_ID}] Error reading/sending audio: {e}")
    else:
         print(f"[Client {CLIENT_ID}] Dummy audio file not found: {DUMMY_AUDIO_PATH}, skipping audio send.")


    # 6. Send Text after media
    print(f"[Client {CLIENT_ID}] Sending Text after media...")
    text_req_2 = blind_assist_pb2.ClientRequest(
        text_part=blind_assist_pb2.TextPart(text="What was in the image and audio?")
    )
    yield text_req_2
    await asyncio.sleep(0.5)

    # 7. End Turn 2
    print(f"[Client {CLIENT_ID}] Sending End of Turn 2...")
    yield blind_assist_pb2.ClientRequest(end_of_turn=True)

    print(f"[Client {CLIENT_ID}] Finished sending all requests.")


# --- Main Client Logic ---

async def run_test_client():
    """Connects to the server and runs the chat stream test."""
    create_dummy_files() # Ensure dummy files exist

    print(f"Attempting to connect to server at {SERVER_ADDRESS}...")
    async with grpc.aio.insecure_channel(SERVER_ADDRESS) as channel:
        print("Channel created.")
        stub = blind_assist_pb2_grpc.GeminiLiveStub(channel)
        print(f"--- Starting ChatStream (Client ID: {CLIENT_ID}) ---")

        try:
            # Start the bidirectional stream
            # Pass the async generator directly to the stub call
            response_iterator = stub.ChatStream(generate_requests())

            # Concurrently process responses from the server
            print(f"[Client {CLIENT_ID}] Waiting for server responses...")
            async for response in response_iterator:
                if response.HasField("text_part"):
                    print(f"[Server Response] Text: {response.text_part.text}")
                elif response.HasField("gemini_audio_part"):
                    audio_info = response.gemini_audio_part
                    print(f"[Server Response] Audio Chunk:"
                          f" Size={len(audio_info.audio_data)} bytes,"
                          f" Mime={audio_info.mime_type},"
                          f" Rate={audio_info.sample_rate}")
                    # Here you would typically buffer or play the audio_data
                elif response.HasField("error_part"):
                    print(f"[Server Response] Error: {response.error_part.message}")
                elif response.turn_complete:
                    print("[Server Response] Turn Complete Signal Received.")
                else:
                    print("[Server Response] Received an empty or unknown message type.")

        except grpc.aio.AioRpcError as e:
            print(f"\n!!! gRPC Error !!!")
            print(f"  Code: {e.code()}")
            print(f"  Details: {e.details()}")
            # traceback.print_exc() # Uncomment for full stack trace
        except Exception as e:
            print(f"\n!!! An unexpected error occurred in the client !!!")
            print(f"  Error: {e}")
            traceback.print_exc()
        finally:
            print(f"--- ChatStream Finished (Client ID: {CLIENT_ID}) ---")


if __name__ == '__main__':
    print("Starting gRPC Test Client...")
    if os.name == 'nt': # Required for asyncio on Windows sometimes
       asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    try:
        asyncio.run(run_test_client())
    except KeyboardInterrupt:
        print("\nClient interrupted by user.")
    print("gRPC Test Client finished.")