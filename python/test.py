import asyncio
import grpc
import logging
import os
import traceback

import gemini_chat_pb2
import gemini_chat_pb2_grpc

SERVER_ADDRESS = 'localhost:50051'

DUMMY_IMAGE_PATH = "dummy_image.jpg"
DUMMY_AUDIO_PATH = "./audio/dummy_audio2.wav"

async def generate_requests():
    # 1) Send an image
    req = gemini_chat_pb2.ChatRequest()
    with open(DUMMY_IMAGE_PATH, "rb") as f:
        req.image.data = f.read()
    req.image.format = "jpeg"
    req.image.width = 640
    req.image.height = 480
    logging.info("Client: sending image")
    
    with open(DUMMY_AUDIO_PATH, "rb") as f:
        req.audio.data = f.read()
    req.audio.format = "wav"
    req.audio.sample_rate_hz = 0
    logging.info("Client: sending audio")
    req.request_id = "1"
    
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
