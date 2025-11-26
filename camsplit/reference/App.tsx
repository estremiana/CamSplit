import React, { useState } from 'react';
import StepAmount from './components/StepAmount';
import StepDetails from './components/StepDetails';
import StepSplit from './components/StepSplit';
import { ExpenseData, Member, SplitType } from './types';

// Mock Data
const MOCK_MEMBERS: Member[] = [
    { id: 'u1', name: 'Daniel Estrella', avatar: 'DE' },
    { id: 'u2', name: 'Emily Chen', avatar: 'EC' },
    { id: 'u3', name: 'Max Power', avatar: 'MP' },
    { id: 'u4', name: 'Cassandra V', avatar: 'CV' },
    { id: 'u5', name: 'Sixtine R', avatar: 'SR' },
    { id: 'u6', name: 'John Doe', avatar: 'JD' },
];

const INITIAL_DATA: ExpenseData = {
    amount: 0,
    title: '',
    date: new Date().toISOString().split('T')[0],
    category: '',
    payerId: 'u1',
    groupId: 'g1',
    splitType: SplitType.EQUAL,
    splitDetails: {},
    involvedMembers: MOCK_MEMBERS.map(m => m.id), // Default everyone involved
    items: [],
};

const App: React.FC = () => {
  const [step, setStep] = useState(0);
  const [expenseData, setExpenseData] = useState<ExpenseData>(INITIAL_DATA);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const updateData = (updates: Partial<ExpenseData>) => {
    setExpenseData(prev => ({ ...prev, ...updates }));
  };

  const handleNext = () => setStep(prev => prev + 1);
  const handleBack = () => setStep(prev => prev - 1);

  const handleSubmit = () => {
    setIsSubmitting(true);
    console.log("Submitting Expense:", expenseData);
    
    // Simulate API call
    setTimeout(() => {
        setIsSubmitting(false);
        alert(`Expense "${expenseData.title || 'Untitled'}" for €${expenseData.amount} created!`);
        // Reset or redirect
        setStep(0);
        setExpenseData(INITIAL_DATA);
    }, 1500);
  };

  if (isSubmitting) {
      return (
          <div className="min-h-screen bg-white flex flex-col items-center justify-center p-6">
              <div className="w-16 h-16 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin mb-4"></div>
              <h2 className="text-xl font-bold text-slate-800">Creating Expense...</h2>
              <p className="text-slate-500">Notifying the group</p>
          </div>
      );
  }

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center md:p-6">
      <div className="w-full max-w-md bg-white md:rounded-3xl md:shadow-2xl h-[100dvh] md:h-[800px] flex flex-col overflow-hidden relative">
        
        {/* Progress Bar */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-slate-100">
            <div 
                className="h-full bg-indigo-500 transition-all duration-500 ease-out"
                style={{ width: `${((step + 1) / 3) * 100}%` }}
            ></div>
        </div>

        <div className="flex-1 p-6 overflow-hidden relative">
            {step === 0 && (
                <StepAmount 
                    data={expenseData} 
                    updateData={updateData} 
                    onNext={handleNext}
                    onCancel={() => alert("Cancel flow")}
                />
            )}
            {step === 1 && (
                <StepDetails 
                    data={expenseData}
                    members={MOCK_MEMBERS}
                    updateData={updateData}
                    onNext={handleNext}
                    onBack={handleBack}
                />
            )}
            {step === 2 && (
                <StepSplit 
                    data={expenseData}
                    members={MOCK_MEMBERS}
                    updateData={updateData}
                    onBack={handleBack}
                    onSubmit={handleSubmit}
                />
            )}
        </div>
      </div>
    </div>
  );
};

export default App;