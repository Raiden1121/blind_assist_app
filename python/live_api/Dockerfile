FROM python:3.10-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製整個專案，包括 generated stub
COPY . .

EXPOSE 50051
CMD ["python", "liveapi_server.py"]
