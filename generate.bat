protoc --dart_out=grpc:lib/generated -Iprotos python/gemini_chat.proto  --proto_path python
cd python
python run_codegen.py
cd ..