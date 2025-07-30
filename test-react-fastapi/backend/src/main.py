from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# CORS設定：React（フロントエンド）からのリクエストを許可
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI from Docker!!!"}

# 
@app.get("/api/hello")
def hello():
    return {"message": "Hello from FastAPI!!!"}

# ReactからのPOSTリクエストを受け取る
class Item(BaseModel):
    name: str

@app.post("/api/send")
def receive_data(item: Item):
    return {"received": item.name}