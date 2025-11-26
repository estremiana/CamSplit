import { GoogleGenAI, Type } from "@google/genai";
import { ScannedReceiptData } from '../types';

export const scanReceipt = async (base64Image: string): Promise<ScannedReceiptData> => {
  if (!process.env.API_KEY) {
    console.error("API Key missing");
    throw new Error("API Key is missing. Please check your configuration.");
  }

  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: {
        parts: [
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: base64Image
            }
          },
          {
            text: "Analyze this receipt. Extract the total amount, the merchant name (as the title), the date (YYYY-MM-DD), a category. Also extract the line items. If an item has a quantity greater than 1 (e.g., '2 x Burger'), please capture the quantity and the UNIT price."
          }
        ]
      },
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            total: { type: Type.NUMBER },
            merchant: { type: Type.STRING },
            date: { type: Type.STRING },
            category: { type: Type.STRING },
            items: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  name: { type: Type.STRING },
                  price: { type: Type.NUMBER, description: "The price of a single unit" },
                  quantity: { type: Type.NUMBER, description: "The count of items" }
                }
              }
            }
          }
        }
      }
    });

    const text = response.text;
    if (!text) throw new Error("No response from AI");
    
    return JSON.parse(text) as ScannedReceiptData;

  } catch (error) {
    console.error("Gemini Scan Error:", error);
    throw error;
  }
};