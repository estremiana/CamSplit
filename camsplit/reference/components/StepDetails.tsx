import React from 'react';
import { Users, Calendar, Tag, User, ChevronRight } from 'lucide-react';
import { ExpenseData, Member } from '../types';

interface Props {
  data: ExpenseData;
  members: Member[];
  updateData: (updates: Partial<ExpenseData>) => void;
  onNext: () => void;
  onBack: () => void;
}

const StepDetails: React.FC<Props> = ({ data, members, updateData, onNext, onBack }) => {
  const currentPayer = members.find(m => m.id === data.payerId);

  return (
    <div className="flex flex-col h-full animate-in fade-in slide-in-from-right-8 duration-500">
      <div className="flex justify-between items-center mb-6">
        <button onClick={onBack} className="text-slate-500 hover:text-slate-700">Back</button>
        <span className="font-semibold text-slate-900">2 of 3</span>
        <button 
            onClick={onNext} 
            className="font-semibold text-indigo-600"
        >
            Next
        </button>
      </div>

      <div className="flex-1 space-y-6">
        <h2 className="text-2xl font-bold text-slate-800 mb-6">The Details</h2>

        {/* Group Selector */}
        <div className="space-y-2">
            <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 ml-1">Group</label>
            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between active:bg-slate-50 transition-colors cursor-pointer">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600">
                        <Users className="w-5 h-5" />
                    </div>
                    <div>
                        <div className="font-semibold text-slate-800">Trip to Paris</div>
                        <div className="text-xs text-slate-500">10 Members</div>
                    </div>
                </div>
                <ChevronRight className="w-5 h-5 text-slate-400" />
            </div>
        </div>

        {/* Payer Selector */}
        <div className="space-y-2">
             <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 ml-1">Who Paid?</label>
             <div className="relative">
                 <select 
                    value={data.payerId}
                    onChange={(e) => updateData({ payerId: e.target.value })}
                    className="w-full appearance-none bg-white p-4 pl-14 pr-10 rounded-2xl border border-slate-200 shadow-sm text-slate-800 font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                 >
                    {members.map(m => (
                        <option key={m.id} value={m.id}>{m.id === 'u1' ? 'You' : m.name}</option>
                    ))}
                 </select>
                 <div className="absolute left-4 top-1/2 -translate-y-1/2 text-indigo-500">
                     <User className="w-5 h-5" />
                 </div>
             </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
             {/* Date */}
            <div className="space-y-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 ml-1">Date</label>
                <div className="relative">
                    <input 
                        type="date" 
                        value={data.date}
                        onChange={(e) => updateData({ date: e.target.value })}
                        className="w-full bg-white p-3 pl-10 rounded-2xl border border-slate-200 shadow-sm text-sm font-medium text-slate-800 focus:outline-none"
                    />
                    <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                </div>
            </div>

            {/* Category */}
            <div className="space-y-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 ml-1">Category</label>
                <div className="relative">
                    <input 
                        type="text" 
                        list="categories"
                        value={data.category}
                        onChange={(e) => updateData({ category: e.target.value })}
                        placeholder="General"
                        className="w-full bg-white p-3 pl-10 rounded-2xl border border-slate-200 shadow-sm text-sm font-medium text-slate-800 focus:outline-none"
                    />
                    <Tag className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <datalist id="categories">
                        <option value="Food & Drink" />
                        <option value="Transport" />
                        <option value="Accommodation" />
                        <option value="Entertainment" />
                        <option value="Groceries" />
                    </datalist>
                </div>
            </div>
        </div>
      </div>
    </div>
  );
};

export default StepDetails;