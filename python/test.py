import asyncio
import grpc
import logging
import os
import traceback

import gemini_chat_pb2
import gemini_chat_pb2_grpc

SERVER_ADDRESS = 'localhost:50051'
# SERVER_ADDRESS = '34.46.68.206:1025'

DUMMY_IMAGE_PATH = "dummy_image.jpg"
DUMMY_AUDIO_PATH = "./audio/dummy_audio1.wav"

async def generate_requests():
    # 1) Send an image
     req = gemini_chat_pb2.ChatRequest()
    
     with open(DUMMY_AUDIO_PATH, "rb") as f:
        req.audio.data = f.read()
     req.audio.format = "wav"
     req.audio.sample_rate_hz = 0
     logging.info("Client: sending audio")
     req.request_id = "1"
    
     img1 = gemini_chat_pb2.ImageInput()
     with open(DUMMY_IMAGE_PATH, "rb") as f:
        img1.data = f.read()
     img1.format = "jpeg"
     img1.width = 640
     img1.height = 480
    
        
     req.multi_images.images.extend([img1])

     req.location.lat = 24.99241723662809 
     req.location.lng = 121.49902199440811

     yield req

     await asyncio.sleep(0.1)

    # end of stream

async def run_chat_stream():
    async with grpc.aio.insecure_channel(SERVER_ADDRESS) as channel:
        stub = gemini_chat_pb2_grpc.GeminiChatStub(channel)
        try:
            async for resp in stub.ChatStream(generate_requests()):
                logging.info(f"Response: {resp}")
        except grpc.aio.AioRpcError as e:
            logging.error(f"gRPC Error: {e.code()} – {e.details()}")
        except Exception:
            logging.error("Unexpected error", exc_info=True)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s %(levelname)s %(message)s")
    # Windows event loop fix
    if os.name == "nt":
        asyncio.set_event_loop_policy(
            asyncio.WindowsSelectorEventLoopPolicy()
        )
    asyncio.run(run_chat_stream())
