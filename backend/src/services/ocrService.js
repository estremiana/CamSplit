const { DocumentAnalysisClient, AzureKeyCredential } = require('@azure/ai-form-recognizer');

const client = new DocumentAnalysisClient(
  process.env.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT,
  new AzureKeyCredential(process.env.AZURE_DOCUMENT_INTELLIGENCE_KEY)
);

exports.extractBillData = async (imageUrl) => {
  try {
    // Analyze the document
    const poller = await client.beginAnalyzeDocumentFromUrl("prebuilt-receipt", imageUrl);
    const result = await poller.pollUntilDone();

    // Extract items, quantities, and prices
    const items = [];
    let total = 0;

    // // Import existing OCR result from JSON file for testing/development
    // const fs = require('fs');
    // const path = require('path');
    
    // // Use a specific existing log file instead of making API calls
    // const logDir = path.join(__dirname, '../../logs');
    // const existingLogFile = path.join(logDir, 'ocr-result-2025-07-02T00-33-14-343Z.json');
    
    // // Check if the log file exists
    // if (!fs.existsSync(existingLogFile)) {
    //   throw new Error('Log file not found. Please ensure the OCR result file exists.');
    // }
    
    // // Read and parse the existing result
    // const result = JSON.parse(fs.readFileSync(existingLogFile, 'utf8'));
    // console.log(`Using existing OCR result from: ${existingLogFile}`);
    
    
    // Parse the result and extract structured data
    if (result.documents && result.documents.length > 0) {
      const document = result.documents[0];
      // Extract items from the receipt
      if (document.fields.Items && document.fields.Items.values) {
        for (const item of document.fields.Items.values) {
          const itemProperties = item.properties;
          if (itemProperties) {
            const description = itemProperties.Description?.value || 'Unknown Item';
            const quantity = itemProperties.Quantity?.value || 1;
            const totalPrice = itemProperties.TotalPrice?.value || 0;
            const unitPrice = itemProperties.Price?.value || totalPrice;
            items.push({
              description: description,
              quantity: quantity,
              total_price: parseFloat(totalPrice),
              unit_price: parseFloat(unitPrice)
            });
          }
        }
      }
      if (document.fields.Total) {
        total = document.fields.Total.value;
      } else {
        total = items.reduce((acc, item) => acc + (item.totalPrice || 0), 0);
      }
    }

    return { items, total };
  } catch (error) {
    console.error('OCR extraction error:', error);
    throw error;
  }
};
