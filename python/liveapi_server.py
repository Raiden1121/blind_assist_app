import os
import asyncio
import logging
from contextlib import suppress

import grpc
from google import genai
from dotenv import load_dotenv

import blind_assist_pb2
import blind_assist_pb2_grpc

load_dotenv()

# Gemini Configuration
MODEL_NAME_DEFAULT = "models/gemini-2.0-flash-live-001"
CONFIG_DEFAULT = {"response_modalities": ["AUDIO", "TEXT"]}

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable not set.")

# Initialize Gemini HTTP and AIO clients
gemini_global_client = genai.Client(http_options={"api_version": "v1beta"}, api_key=GEMINI_API_KEY)
logging.basicConfig(level=logging.INFO)


class GeminiLiveServicer(blind_assist_pb2_grpc.GeminiLiveServicer):

    async def ChatStream(self, request_iterator, context):
        client_response_queue = asyncio.Queue()
        active_session = None
        receive_task = None

        async def _handle_gemini_responses(session):
            try:
                while True:
                    # **Await** the coroutine to get an async iterable of turns
                    gemini_turn = await session.receive()
                    async for part in gemini_turn:
                        if part.text:
                            await client_response_queue.put(
                                blind_assist_pb2.ServerResponse(
                                    text_part=blind_assist_pb2.TextPart(text=part.text)
                                )
                            )
                        if part.data:
                            await client_response_queue.put(
                                blind_assist_pb2.ServerResponse(
                                    gemini_audio_part=blind_assist_pb2.AudioPart(data=part.data)
                                )
                            )
                    # signal end of one turn
                    await client_response_queue.put(
                        blind_assist_pb2.ServerResponse(turn_complete=True)
                    )
            except Exception as e:
                logging.exception("Error in Gemini response handler")
                await client_response_queue.put(
                    blind_assist_pb2.ServerResponse(
                        error_part=blind_assist_pb2.ErrorPart(message=str(e))
                    )
                )

        async def _client_to_gemini():
            nonlocal active_session, receive_task
            async for req in request_iterator:
                # Initialize or reinitialize session
                if req.HasField("initial_config"):
                    # Tear down old session if any
                    if active_session:
                        await active_session.__aexit__(None, None, None)
                        receive_task.cancel()
                    cfg = {
                        **CONFIG_DEFAULT,
                        **{ "response_modalities": list(req.initial_config.modalities) }
                    }
                    active_session = (
                        gemini_global_client.aio.live
                            .connect(model=req.initial_config.model_name or MODEL_NAME_DEFAULT,
                                     config=cfg)
                    )
                    await active_session.__aenter__()
                    receive_task = asyncio.create_task(_handle_gemini_responses(active_session))

                # Send text from client
                elif req.HasField("text_part"):
                    await active_session.send(input=req.text_part.text)

                # Send audio bytes from client
                elif req.HasField("audio_part"):
                    await active_session.send_audio(content=req.audio_part.data)

                # handle end_of_turn from client
                elif req.end_of_turn:
                    await active_session.end_input()

            # client done: clean up the session
            if active_session:
                await active_session.__aexit__(None, None, None)

        # Kick off client→Gemini pump
        client_task = asyncio.create_task(_client_to_gemini())

        # Interleave yields back to gRPC client
        while True:
            if client_task.done() and client_response_queue.empty():
                break
            try:
                resp = await asyncio.wait_for(client_response_queue.get(), timeout=0.1)
                yield resp
            except asyncio.TimeoutError:
                continue

        # Final cleanup
        if receive_task:
            receive_task.cancel()
            with suppress(asyncio.CancelledError):
                await receive_task

        logging.info("ChatStream complete, closing.")

async def serve():
    server = grpc.aio.server()
    blind_assist_pb2_grpc.add_GeminiLiveServicer_to_server(GeminiLiveServicer(), server)
    listen_addr = '[::]:50051'
    server.add_insecure_port(listen_addr)
    logging.info(f"Starting gRPC server on {listen_addr}...")
    await server.start()
    logging.info("gRPC server started.")
    await server.wait_for_termination()

if __name__ == '__main__':
    asyncio.run(serve())
