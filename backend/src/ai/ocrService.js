const { DocumentAnalysisClient, AzureKeyCredential } = require('@azure/ai-form-recognizer');
const vision = require('@google-cloud/vision');

class OCRService {
  constructor() {
    // Initialize Azure Form Recognizer client
    if (process.env.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT && process.env.AZURE_DOCUMENT_INTELLIGENCE_KEY) {
      this.azureClient = new DocumentAnalysisClient(
        process.env.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT,
        new AzureKeyCredential(process.env.AZURE_DOCUMENT_INTELLIGENCE_KEY)
      );
    }

    // Initialize Google Cloud Vision client
    if (process.env.GOOGLE_CLOUD_VISION_API_KEY) {
      this.googleClient = new vision.ImageAnnotatorClient({
        keyFilename: process.env.GOOGLE_CLOUD_VISION_API_KEY
      });
    }
  }

  // Extract text from image using Azure Form Recognizer
  async extractTextWithAzure(imageUrl) {
    try {
      if (!this.azureClient) {
        throw new Error('Azure Form Recognizer not configured');
      }

      const poller = await this.azureClient.beginAnalyzeDocumentFromUrl("prebuilt-receipt", imageUrl);
      const result = await poller.pollUntilDone();

      return {
        provider: 'azure',
        success: true,
        data: result,
        rawText: this.extractRawTextFromAzureResult(result)
      };
    } catch (error) {
      console.error('Azure OCR error:', error);
      return {
        provider: 'azure',
        success: false,
        error: error.message
      };
    }
  }

  // Extract text from image using Google Cloud Vision
  async extractTextWithGoogle(imageUrl) {
    try {
      if (!this.googleClient) {
        throw new Error('Google Cloud Vision not configured');
      }

      const [result] = await this.googleClient.textDetection(imageUrl);
      const detections = result.textAnnotations;

      return {
        provider: 'google',
        success: true,
        data: result,
        rawText: detections[0]?.description || ''
      };
    } catch (error) {
      console.error('Google OCR error:', error);
      return {
        provider: 'google',
        success: false,
        error: error.message
      };
    }
  }

  // Main text extraction method with fallback
  async extractTextFromImage(imageUrl) {
    console.log('Starting OCR extraction for:', imageUrl);

    // Try Azure first (better for receipts)
    let result = await this.extractTextWithAzure(imageUrl);
    
    // If Azure fails, try Google as fallback
    if (!result.success && this.googleClient) {
      console.log('Azure failed, trying Google Cloud Vision...');
      result = await this.extractTextWithGoogle(imageUrl);
    }

    if (!result.success) {
      throw new Error(`OCR extraction failed: ${result.error}`);
    }

    return result;
  }

  // Extract raw text from Azure Form Recognizer result
  extractRawTextFromAzureResult(result) {
    let rawText = '';
    
    if (result.content) {
      rawText = result.content;
    } else if (result.paragraphs) {
      rawText = result.paragraphs.map(p => p.content).join('\n');
    }

    return rawText;
  }

  // Extract structured data from Azure Form Recognizer result
  extractStructuredDataFromAzure(result) {
    const structuredData = {
      merchant: null,
      date: null,
      total: null,
      subtotal: null,
      tax: null,
      items: [],
      confidence: 0.8
    };

    try {
      if (result.documents && result.documents.length > 0) {
        const document = result.documents[0];
        
        // Extract merchant name
        if (document.fields.MerchantName) {
          structuredData.merchant = document.fields.MerchantName.value;
        }

        // Extract date
        if (document.fields.TransactionDate) {
          structuredData.date = document.fields.TransactionDate.value;
        }

        // Extract total amount
        if (document.fields.Total) {
          structuredData.total = parseFloat(document.fields.Total.value);
        }

        // Extract subtotal
        if (document.fields.Subtotal) {
          structuredData.subtotal = parseFloat(document.fields.Subtotal.value);
        }

        // Extract tax
        if (document.fields.TotalTax) {
          structuredData.tax = parseFloat(document.fields.TotalTax.value);
        }

        // Extract items
        if (document.fields.Items && document.fields.Items.values) {
          for (const item of document.fields.Items.values) {
            const itemProperties = item.properties;
            if (itemProperties) {
              const description = itemProperties.Description?.value || 'Unknown Item';
              const quantity = itemProperties.Quantity?.value || 1;
              const totalPrice = itemProperties.TotalPrice?.value || 0;
              const unitPrice = itemProperties.Price?.value || totalPrice;

              // Extract confidence scores
              const descriptionConfidence = itemProperties.Description?.confidence || 0.5;
              const quantityConfidence = itemProperties.Quantity?.confidence || 0.5;
              const totalPriceConfidence = itemProperties.TotalPrice?.confidence || 0.5;
              const unitPriceConfidence = itemProperties.Price?.confidence || 0.5;

              // Calculate average confidence for the item
              const avgConfidence = (descriptionConfidence + quantityConfidence + totalPriceConfidence + unitPriceConfidence) / 4;

              structuredData.items.push({
                description: description,
                quantity: parseInt(quantity),
                unit_price: parseFloat(unitPrice),
                total_price: parseFloat(totalPrice),
                confidence: avgConfidence
              });
            }
          }
        }
      }
    } catch (error) {
      console.error('Error extracting structured data:', error);
    }

    return structuredData;
  }

  // Extract structured data from Google Cloud Vision result
  extractStructuredDataFromGoogle(result) {
    const structuredData = {
      merchant: null,
      date: null,
      total: null,
      subtotal: null,
      tax: null,
      items: [],
      confidence: 0.6
    };

    try {
      const text = result.rawText;
      const lines = text.split('\n');

      // Simple parsing logic for Google Vision results
      // This is a basic implementation - could be enhanced with more sophisticated parsing
      
      // Look for total amount (common patterns)
      const totalPattern = /(?:total|amount|sum|due)[:\s]*\$?(\d+\.?\d*)/i;
      for (const line of lines) {
        const match = line.match(totalPattern);
        if (match && !structuredData.total) {
          structuredData.total = parseFloat(match[1]);
          break;
        }
      }

      // Look for date patterns
      const datePattern = /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})|(\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})/;
      for (const line of lines) {
        const match = line.match(datePattern);
        if (match) {
          structuredData.date = match[0];
          break;
        }
      }

      // Basic item extraction (this is simplified)
      const pricePattern = /\$?(\d+\.?\d*)/g;
      for (const line of lines) {
        const prices = line.match(pricePattern);
        if (prices && prices.length > 0) {
          const price = parseFloat(prices[0].replace('$', ''));
          if (price > 0 && price < 1000) { // Reasonable price range
            const description = line.replace(pricePattern, '').trim();
            if (description.length > 0) {
              structuredData.items.push({
                description: description,
                quantity: 1,
                unit_price: price,
                total_price: price,
                confidence: 0.4 // Lower confidence for Google Vision parsing
              });
            }
          }
        }
      }
    } catch (error) {
      console.error('Error extracting structured data from Google:', error);
    }

    return structuredData;
  }

  // Main method to extract structured data from image
  async extractStructuredDataFromImage(imageUrl) {
    const ocrResult = await this.extractTextFromImage(imageUrl);
    
    if (ocrResult.provider === 'azure') {
      return this.extractStructuredDataFromAzure(ocrResult.data);
    } else if (ocrResult.provider === 'google') {
      return this.extractStructuredDataFromGoogle(ocrResult);
    }

    throw new Error('No OCR provider available');
  }
}

module.exports = new OCRService(); 