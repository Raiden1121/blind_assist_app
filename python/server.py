from concurrent import futures
import grpc, json
import blind_assist_pb2, blind_assist_pb2_grpc
from googlemaps import Client as GMaps
from google_generative_ai import GenerativeModel, FunctionDeclaration, Schema, Tool, ToolConfig, FunctionCallingConfig
from tool_schemas import geocodeDecl, routeDecl
import httpx

GMAPS_KEY = "YOUR_GOOGLE_MAPS_KEY"
GEMINI_KEY = "YOUR_GEMINI_API_KEY"

class NavServiceServicer(nav_service_pb2_grpc.NavServiceServicer):
  def __init__(self):
    self.gmaps = GMaps.client(key=GMAPS_KEY)
    # 建立 Gemini client    
    self.llm = GenerativeModel(
      api_key=GEMINI_KEY,
      model="gemini-2.0-flash",
      system_instruction="你是一個導航助理...",
      tools=[Tool(function_declarations=[geocodeDecl, routeDecl])],
      tool_config=ToolConfig(
        function_calling_config=FunctionCallingConfig(mode="auto")
      )
    )

  def GetDestLocation(self, req, ctx):
    if req.query == "CURRENT_LOCATION":
      return nav_service_pb2.LocationResponse(lat=req.current_lat, lng=req.current_lng)
    geo = self.gmaps.geocode(req.query)
    loc = geo[0]["geometry"]["location"]
    return nav_service_pb2.LocationResponse(lat=loc["lat"], lng=loc["lng"])

  async def GetRoutes(self, req, ctx):
    directions = self.gmaps.directions(
      origin=(req.origin_lat, req.origin_lng),
      destination=(req.dest_lat,   req.dest_lng),
      mode=req.mode.lower()
    )
    
    hdr = {
        "Content-Type": "application/json",
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps"
    }
    
    body = {
        "origin": {
            "location": {
                "latLng": {
                    "latitude": req.origin_lat,
                    "longitude": req.origin_lng
                }
            }
        },
        "destination": {
            "location": {
                "latLng": {
                    "latitude": req.dest_lat,   
                    "longitude": req.dest_lng
                }
            }
        },
        "travelMode": req.mode.upper(),
    }
    url = f"https://routes.googleapis.com/directions/v2:computeRoutes?key={GMAPS_KEY}"
    
    async with httpx.AsyncClient(timeout=20) as c:
        r = await c.post(url, headers=hdr, json=body)
    
    r.raise_for_status()
    data = r.json()
    
    steps = data[0]["legs"][0]["steps"]
    resp = []
    for s in steps:
      instr = s["navigationInstruction"]
      dist  = s["distanceMeters"]
      resp.append(nav_service_pb2.RouteStep(instruction=instr, distance=dist))
    return nav_service_pb2.RouteResponse(steps=resp)

  def AskLLM(self, req, ctx):
    chat = self.llm.start_chat()
    turn = chat.send_message(req.user_text)
    # 等同於前面示範的 function-calling loop...
    # 最後回傳 steps 與 reply_text
    steps, reply = ... 
    # 把 Python dict 轉成 RouteStep list
    rr = [nav_service_pb2.RouteStep(instruction=s["text"], distance=0) for s in steps]
    return nav_service_pb2.LLMResponse(steps=rr, reply_text=reply)

  def GetNavigateMessage(self, req, ctx):
    # 你可以本地化創建提示文字
    msg = f"請朝 {req.step.instruction} 前進，大約 {req.step.distance} 公尺。"
    return nav_service_pb2.NavigateResponse(message=msg)

def serve():
  server = grpc.server(futures.ThreadPoolExecutor(max_workers=8))
  nav_service_pb2_grpc.add_NavServiceServicer_to_server(NavServiceServicer(), server)
  server.add_insecure_port('[::]:50051')
  server.start()
  server.wait_for_termination()

if __name__ == '__main__':
  serve()
