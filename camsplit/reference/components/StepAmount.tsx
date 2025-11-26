import React, { useState, useRef } from 'react';
import { Camera, Upload, Sparkles, Loader2, X } from 'lucide-react';
import { ExpenseData, ReceiptItem } from '../types';
import { scanReceipt } from '../services/gemini';

interface Props {
  data: ExpenseData;
  updateData: (updates: Partial<ExpenseData>) => void;
  onNext: () => void;
  onCancel: () => void;
}

const StepAmount: React.FC<Props> = ({ data, updateData, onNext, onCancel }) => {
  const [isScanning, setIsScanning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsScanning(true);
    
    // Convert to base64
    const reader = new FileReader();
    reader.onloadend = async () => {
      const base64String = reader.result as string;
      const base64Data = base64String.split(',')[1];

      try {
        const result = await scanReceipt(base64Data);
        
        // Map items to ReceiptItem WITHOUT exploding them
        const receiptItems: ReceiptItem[] = (result.items || []).map((item, idx) => {
            const qty = item.quantity && item.quantity > 0 ? item.quantity : 1;
            const unitPrice = item.price;
            const totalPrice = unitPrice * qty;

            return {
                id: `item-${Date.now()}-${idx}`,
                name: item.name,
                quantity: qty,
                unitPrice: unitPrice,
                price: totalPrice,
                assignments: {}, // Empty map
                isCustomSplit: false
            };
        });

        updateData({
          receiptImage: base64String,
          amount: result.total || data.amount,
          title: result.merchant || data.title,
          date: result.date || data.date,
          category: result.category || data.category,
          items: receiptItems
        });
      } catch (err) {
        alert("Failed to read receipt. Please enter details manually.");
      } finally {
        setIsScanning(false);
      }
    };
    reader.readAsDataURL(file);
  };

  return (
    <div className="flex flex-col h-full animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex justify-between items-center mb-6">
        <button onClick={onCancel} className="text-slate-500 hover:text-slate-700">Cancel</button>
        <span className="font-semibold text-slate-900">1 of 3</span>
        <button 
            onClick={onNext} 
            disabled={!data.amount}
            className={`font-semibold ${data.amount ? 'text-indigo-600' : 'text-slate-300'}`}
        >
            Next
        </button>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center space-y-8">
        {/* Amount Input */}
        <div className="w-full text-center relative">
            <span className="absolute top-2 left-1/2 -translate-x-[4rem] text-3xl text-slate-400">€</span>
            <input 
                type="number" 
                value={data.amount || ''}
                onChange={(e) => updateData({ amount: parseFloat(e.target.value) })}
                placeholder="0.00"
                className="w-full bg-transparent text-center text-6xl font-bold text-slate-800 focus:outline-none placeholder:text-slate-200"
                autoFocus
            />
        </div>

        {/* Title Input */}
        <div className="w-full max-w-xs mx-auto">
             <input 
                type="text" 
                value={data.title}
                onChange={(e) => updateData({ title: e.target.value })}
                placeholder="What is this for?"
                className="w-full text-center text-xl border-b-2 border-slate-100 focus:border-indigo-500 focus:outline-none py-2 bg-transparent transition-colors"
            />
        </div>

        {/* AI Scanner Button */}
        <div className="pt-8 w-full max-w-xs">
            <input 
                type="file" 
                accept="image/*" 
                className="hidden" 
                ref={fileInputRef}
                onChange={handleFileChange}
            />
            
            {!data.receiptImage ? (
                <button 
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isScanning}
                    className="w-full group relative flex items-center justify-center gap-3 bg-gradient-to-r from-indigo-50 to-purple-50 hover:from-indigo-100 hover:to-purple-100 border border-indigo-100 text-indigo-700 p-4 rounded-2xl transition-all active:scale-95 shadow-sm"
                >
                    {isScanning ? (
                        <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            <span>Reading Receipt...</span>
                        </>
                    ) : (
                        <>
                             <div className="bg-white p-2 rounded-full shadow-sm text-indigo-600 group-hover:text-indigo-700">
                                <Sparkles className="w-5 h-5" />
                            </div>
                            <span className="font-medium">Scan Receipt with AI</span>
                        </>
                    )}
                </button>
            ) : (
                <div className="relative rounded-xl overflow-hidden shadow-md border border-slate-200">
                    <img src={data.receiptImage} alt="Receipt" className="w-full h-32 object-cover opacity-75" />
                    <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                         <span className="text-white font-medium flex items-center gap-2">
                            <Camera className="w-4 h-4" /> Receipt Attached
                         </span>
                    </div>
                    <button 
                        onClick={() => updateData({ receiptImage: undefined, items: [] })}
                        className="absolute top-2 right-2 bg-white/90 p-1.5 rounded-full text-slate-600 hover:text-red-500"
                    >
                        <X className="w-4 h-4" />
                    </button>
                </div>
            )}
            
            {/* Scanned Items Count Badge */}
            {data.items.length > 0 && (
                <div className="mt-4 text-center">
                    <span className="inline-flex items-center gap-1.5 bg-green-50 text-green-700 px-3 py-1 rounded-full text-sm font-medium border border-green-100">
                        <CheckIcon className="w-3 h-3" />
                        {data.items.length} items found
                    </span>
                </div>
            )}
        </div>
      </div>
      
      {/* Footer Hint */}
      <div className="mt-auto text-center pb-4 text-xs text-slate-400">
        Start by adding an amount or scanning a receipt
      </div>
    </div>
  );
};

const CheckIcon = ({ className }: { className?: string }) => (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" className={className}>
        <polyline points="20 6 9 17 4 12" />
    </svg>
);

export default StepAmount;