import asyncio
import base64
import io
import logging
import os
import traceback
from concurrent import futures

import grpc
from google import genai
# PIL is used in your original script, ensure it's available if you do image processing
# import PIL.Image

# Import generated gRPC files
import blind_assist_pb2
import blind_assist_pb2_grpc

from dotenv import load_dotenv
load_dotenv()

# Gemini Configuration
MODEL_NAME_DEFAULT = "models/gemini-2.0-flash-live-001"
CONFIG_DEFAULT = {"response_modalities": ["AUDIO", "TEXT"]} # Ensure TEXT is included for text replies

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable not set.")

# Initialize Gemini client
# The aio client is needed for live.connect
gemini_global_client = genai.Client(http_options={"api_version": "v1beta"}, api_key=GEMINI_API_KEY)

class GeminiLiveServicer(blind_assist_pb2_grpc.GeminiLiveServicer):
    async def ChatStream(self, request_iterator, context):
        print("Client connected to ChatStream.")
        active_gemini_session = None
        model_name = MODEL_NAME_DEFAULT
        current_gemini_config = CONFIG_DEFAULT.copy()
        
        client_response_queue = asyncio.Queue() # Queue to send responses from Gemini to client
        receive_gemini_task = None # Task for handling responses from Gemini

        try:
            # This inner async function handles receiving from Gemini and putting to a queue for the client
            async def _handle_gemini_responses(session, response_queue):
                try:
                    while True:
                        gemini_turn = session.receive()
                        async for response in gemini_turn:
                            if response.data:  # Audio data from Gemini
                                print("Received audio data from Gemini.")
                                server_msg = blind_assist_pb2.ServerResponse(
                                    gemini_audio_part=blind_assist_pb2.AudioPart(
                                        audio_data=response.data,
                                        mime_type="audio/pcm", # Gemini Live typically sends PCM
                                        sample_rate=24000 # Matches original script RECEIVE_SAMPLE_RATE
                                    )
                                )
                                await response_queue.put(server_msg)
                            if response.text:
                                print(f"Received text from Gemini: {response.text}")
                                server_msg = blind_assist_pb2.ServerResponse(
                                    text_part=blind_assist_pb2.TextPart(text=response.text)
                                )
                                await response_queue.put(server_msg)
                        
                        print("Gemini turn complete from API.")
                        await response_queue.put(blind_assist_pb2.ServerResponse(turn_complete=True))

                except grpc.aio.AbortError:
                    print("gRPC client disconnected while handling Gemini responses.")
                except asyncio.CancelledError:
                    print("Gemini response handler task cancelled.")
                except Exception as e:
                    print(f"Error in _handle_gemini_responses: {e}")
                    traceback.print_exc()
                    await response_queue.put(blind_assist_pb2.ServerResponse(
                        error_part=blind_assist_pb2.ErrorPart(message=f"Gemini response error: {str(e)}")
                    ))
                finally:
                    print("Gemini response handling loop finished.")


            # Main loop to process incoming requests from the client
            async def client_request_loop():
                nonlocal active_gemini_session, model_name, current_gemini_config, receive_gemini_task
                async for client_request in request_iterator:
                    if not active_gemini_session and not client_request.HasField("initial_config"):
                        print("Warning: Received data before initial_config. Using default session or awaiting config.")
                        # Optionally, send an error back or queue the request
                        # For now, we'll require initial_config first or implicitly create session on first data
                        # Let's decide to create session on first relevant data if no initial_config
                        if not (client_request.HasField("text_part") or \
                                client_request.HasField("image_part") or \
                                client_request.HasField("client_audio_part")):
                            print("Awaiting initial_config or data to start session.")
                            continue # Skip if not initial config and not data

                    if client_request.HasField("initial_config"):
                        req_config = client_request.initial_config
                        model_name = req_config.model_name or MODEL_NAME_DEFAULT
                        if req_config.response_modalities:
                            current_gemini_config["response_modalities"] = list(req_config.response_modalities)
                        
                        print(f"Client initial config: model={model_name}, modalities={current_gemini_config['response_modalities']}")

                        if active_gemini_session: # If re-initializing
                            if receive_gemini_task and not receive_gemini_task.done():
                                receive_gemini_task.cancel()
                            await active_gemini_session.close()
                            active_gemini_session = None
                        # Fall through to create session below
                    
                    # Establish Gemini session if not already done or if re-configured
                    if not active_gemini_session:
                        print(f"Connecting to Gemini: {model_name} with {current_gemini_config}")
                        active_gemini_session = gemini_global_client.aio.live.connect(
                            model=model_name,
                            config=current_gemini_config
                        )
                        await active_gemini_session.__aenter__() # Enter context
                        # Start task to listen for Gemini responses
                        if receive_gemini_task and not receive_gemini_task.done(): # Should be None here usually
                           receive_gemini_task.cancel()
                        receive_gemini_task = asyncio.create_task(
                            _handle_gemini_responses(active_gemini_session, client_response_queue)
                        )
                        print("Gemini session started and response handler task created.")


                    if client_request.HasField("text_part"):
                        text = client_request.text_part.text
                        print(f"Sending text to Gemini: '{text}'")
                        await active_gemini_session.send(input=text)

                    elif client_request.HasField("image_part"):
                        image_data = client_request.image_part.image_data
                        mime_type = client_request.image_part.mime_type
                        print(f"Sending image to Gemini: mime_type={mime_type}, size={len(image_data)} bytes")
                        
                        # Gemini Live API expects base64 encoded image data in a dict
                        encoded_image_data = base64.b64encode(image_data).decode('utf-8')
                        gemini_image_input = {"mime_type": mime_type, "data": encoded_image_data}
                        await active_gemini_session.send(input=gemini_image_input)

                    elif client_request.HasField("client_audio_part"):
                        audio_data = client_request.client_audio_part.audio_data
                        mime_type = client_request.client_audio_part.mime_type
                        # sample_rate = client_request.client_audio_part.sample_rate (FYI)
                        print(f"Sending client audio to Gemini: mime_type={mime_type}, size={len(audio_data)} bytes")
                        gemini_audio_input = {"data": audio_data, "mime_type": mime_type}
                        await active_gemini_session.send(input=gemini_audio_input)
                    
                    if client_request.end_of_turn:
                        if active_gemini_session:
                            print("Client signaled end of turn. Relaying to Gemini.")
                            await active_gemini_session.send(end_of_turn=True)
                        else:
                            print("Warning: Client signaled end_of_turn but no active Gemini session.")
                print("Client has finished sending requests.")

            # Main loop to send responses from queue back to the client
            async def server_response_loop():
                while True:
                    try:
                        # Wait for a response from Gemini (via the queue)
                        # If client_request_loop ends and receive_gemini_task is also done, and queue is empty, then break.
                        response_to_client = await client_response_queue.get()
                        yield response_to_client
                        client_response_queue.task_done()
                        if response_to_client.HasField("error_part"): # If fatal error, maybe stop
                            if "Gemini session not initialized" in response_to_client.error_part.message:
                                break
                        if receive_gemini_task and receive_gemini_task.done() and client_response_queue.empty():
                            if not client_requests_task.done() : # if client still sending wait
                                 await asyncio.sleep(0.01) # small sleep before re-checking
                                 if not client_response_queue.empty(): continue # check queue again
                            print("Both Gemini handling and client requests appear done, and queue empty.")
                            break
                    except asyncio.CancelledError:
                        print("Server response loop cancelled.")
                        break
            
            client_requests_task = asyncio.create_task(client_request_loop())
            server_responses_task = asyncio.create_task(server_response_loop()) # This is conceptual, yield does this

            # The `yield from` or iterating through server_response_loop is what sends back to client
            # We need to merge these two main loops: one for receiving from client, one for sending to client
            # The `yield` keyword in an `async def` that takes an iterator makes it a generator for responses

            # Simpler structure:
            # One task for handling client requests and sending to Gemini
            # The main RPC method itself handles getting from client_response_queue and yielding to gRPC client
            
            # Start the task that processes client requests and sends to Gemini
            processing_task = asyncio.create_task(client_request_loop())

            # In this main RPC method, listen to the client_response_queue and yield to the client
            while True:
                try:
                    # Check if processing_task and receive_gemini_task are done and queue is empty
                    processing_done = processing_task.done()
                    gemini_handling_done = receive_gemini_task.done() if receive_gemini_task else True # True if not started
                    
                    if processing_done and gemini_handling_done and client_response_queue.empty():
                        print("All tasks seem complete and queue is empty. Exiting ChatStream main yield loop.")
                        break

                    response_to_client = await asyncio.wait_for(client_response_queue.get(), timeout=0.1)
                    yield response_to_client
                    client_response_queue.task_done()
                except asyncio.TimeoutError:
                    # This timeout allows checking the loop condition (tasks done)
                    continue 
                except asyncio.CancelledError: # This happens if client disconnects
                    print("ChatStream's main yield loop cancelled (client likely disconnected).")
                    break
            
            # Wait for tasks to finish if they haven't
            if not processing_task.done():
                await processing_task # This should complete as request_iterator finishes or cancels
            
        except grpc.aio.AbortError: # This catches client disconnection cleanly
            print("Client connection aborted in ChatStream.")
        except Exception as e:
            print(f"Overall error in ChatStream: {e}")
            traceback.print_exc()
            try:
                yield blind_assist_pb2.ServerResponse(
                    error_part=blind_assist_pb2.ErrorPart(message=f"Server error: {str(e)}")
                )
            except Exception as e2:
                print(f"Failed to send error to client: {e2}") # e.g. if stream already closed
        finally:
            print("ChatStream ended for a client.")
            if receive_gemini_task and not receive_gemini_task.done():
                print("Cancelling Gemini response handler task.")
                receive_gemini_task.cancel()
                try:
                    await receive_gemini_task
                except asyncio.CancelledError:
                    pass # Expected
            if active_gemini_session:
                print("Closing Gemini session.")
                await active_gemini_session.__aexit__(None, None, None) # Ensure context is exited

async def serve():
    server = grpc.aio.server(futures.ThreadPoolExecutor(max_workers=10))
    blind_assist_pb2_grpc.add_GeminiLiveServicer_to_server(GeminiLiveServicer(), server)
    server.add_insecure_port('[::]:50051')
    print("gRPC server started on port 50051...")
    await server.start()
    try:
        await server.wait_for_termination()
    except KeyboardInterrupt:
        print("Server stopping...")
        await server.stop(0) # Graceful stop

if __name__ == '__main__':
    if os.name == 'nt': # Required for asyncio on Windows with ProactorEventLoop
       asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    logging.basicConfig(level=logging.INFO) # Add logging for grpc and other libs if needed
    # Example: logging.getLogger('grpc').setLevel(logging.DEBUG)
    
    asyncio.run(serve())