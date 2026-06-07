import os
from google import genai

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

print("--- Modelos Disponíveis ---")
for model in client.models.list():
    print(f"ID: {model.name}, Display: {model.display_name}")
