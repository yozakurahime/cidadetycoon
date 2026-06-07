import os
import google.generativeai as genai

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

print("--- Modelos que suportam Image Generation ---")
for m in genai.list_models():
    if 'generateImage' in m.supported_generation_methods or 'image' in m.name.lower():
        print(f"Nome: {m.name}, Display: {m.display_name}")

print("\n--- Todos os modelos ---")
for m in genai.list_models():
    print(m.name)
