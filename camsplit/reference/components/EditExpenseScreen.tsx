import React from 'react';
import { ArrowLeft, Calendar, Tag, User, Users, ChevronRight, Pencil, Receipt, Save, AlertCircle, X } from 'lucide-react';
import { ExpenseData, Member, SplitType } from '../types';

interface Props {
  data: ExpenseData;
  members: Member[];
  isEditing: boolean;
  updateData: (updates: Partial<ExpenseData>) => void;
  onEditStart: () => void;
  onSave: () => void;
  onCancel: () => void;
  onEditSplit: () => void;
}

const EditExpenseScreen: React.FC<Props> = ({ 
    data, 
    members, 
    isEditing, 
    updateData, 
    onEditStart, 
    onSave, 
    onCancel, 
    onEditSplit 
}) => {
  
  // Helper to calculate totals per member for display
  const getMemberTotals = () => {
    const totals: Record<string, number> = {};
    members.forEach(m => {
      if (data.splitType === SplitType.ITEMIZED) {
          let sum = 0;
          data.items.forEach(item => {
              const qty = item.assignments[m.id] || 0;
              sum += qty * item.unitPrice;
          });
          totals[m.id] = sum;
      } else if (data.splitType === SplitType.EQUAL) {
          totals[m.id] = data.involvedMembers.includes(m.id) 
              ? data.amount / data.involvedMembers.length 
              : 0;
      } else if (data.splitType === SplitType.PERCENTAGE) {
          const pct = data.splitDetails[m.id] || 0;
          totals[m.id] = data.amount * (pct / 100);
      } else { // EXACT
          totals[m.id] = data.splitDetails[m.id] || 0;
      }
    });
    return totals;
  };

  const memberTotals = getMemberTotals();
  const payer = members.find(m => m.id === data.payerId);

  // Validation Check
  const getUnassignedAmount = () => {
      const assignedTotal = Object.values(memberTotals).reduce((a, b) => a + b, 0);
      return data.amount - assignedTotal;
  };
  
  const unassigned = getUnassignedAmount();
  const isValid = Math.abs(unassigned) < 0.05;

  return (
    <div className="flex flex-col h-full bg-slate-50 animate-in fade-in duration-300">
      
      {/* --- NAVBAR --- */}
      <div className="bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10">
        <button onClick={onCancel} className="text-slate-500 hover:text-slate-800 flex items-center gap-1 text-sm font-medium p-2 -ml-2">
            {isEditing ? <span className="text-slate-600">Cancel</span> : <><ArrowLeft className="w-4 h-4" /> Back</>}
        </button>
        
        <div className="font-semibold text-slate-800">
            {isEditing ? "Edit Expense" : "Expense Details"}
        </div>
        
        <div className="w-16 flex justify-end">
            {isEditing ? (
                 <button 
                    onClick={onSave}
                    disabled={!isValid}
                    className="text-indigo-600 font-bold text-sm disabled:opacity-50 disabled:text-slate-400"
                >
                    Save
                </button>
            ) : (
                <button onClick={onEditStart} className="text-indigo-600 p-2 -mr-2 hover:bg-indigo-50 rounded-full">
                    <Pencil className="w-4 h-4" />
                </button>
            )}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        
        {/* --- HERO SECTION (Amount & Title) --- */}
        <div className="flex flex-col items-center justify-center pt-4 pb-2">
            <div className="relative group">
                <span className={`absolute top-1 left-0 -translate-x-full text-2xl pr-1 ${isEditing ? 'text-slate-400' : 'text-slate-300'}`}>€</span>
                {isEditing ? (
                    <input 
                        type="number"
                        value={data.amount}
                        disabled={data.splitType === SplitType.ITEMIZED}
                        onChange={(e) => updateData({ amount: parseFloat(e.target.value) || 0 })}
                        className={`bg-transparent text-center text-5xl font-bold text-slate-900 focus:outline-none w-48 ${data.splitType === SplitType.ITEMIZED ? 'opacity-70' : 'border-b border-dashed border-slate-300 focus:border-indigo-500'}`}
                    />
                ) : (
                    <span className="text-5xl font-bold text-slate-900 block min-h-[3.5rem]">
                        {data.amount.toFixed(2)}
                    </span>
                )}
                
                {data.splitType === SplitType.ITEMIZED && isEditing && (
                    <div className="text-xs text-center text-slate-400 mt-1 flex items-center justify-center gap-1">
                        <Receipt className="w-3 h-3" /> Sum of items
                    </div>
                )}
            </div>

            {isEditing ? (
                <input 
                    type="text"
                    value={data.title}
                    onChange={(e) => updateData({ title: e.target.value })}
                    className="mt-4 text-center text-lg font-medium text-slate-700 bg-transparent border-b border-transparent hover:border-slate-200 focus:border-indigo-500 focus:outline-none w-full max-w-xs transition-all"
                    placeholder="Expense Title"
                />
            ) : (
                <div className="mt-4 text-center text-lg font-medium text-slate-800">
                    {data.title || "Untitled Expense"}
                </div>
            )}
        </div>

        {/* --- DETAILS CARD --- */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            {/* Payer */}
            <div className="flex items-center p-4 border-b border-slate-100">
                <div className="w-8 h-8 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mr-3">
                    <User className="w-4 h-4" />
                </div>
                <div className="flex-1">
                    <div className="text-xs text-slate-500 font-semibold uppercase">Paid By</div>
                    {isEditing ? (
                        <select 
                            value={data.payerId}
                            onChange={(e) => updateData({ payerId: e.target.value })}
                            className="w-full bg-transparent font-medium text-slate-800 focus:outline-none -ml-1 mt-0.5"
                        >
                             {members.map(m => (
                                <option key={m.id} value={m.id}>{m.id === 'u1' ? 'You' : m.name}</option>
                            ))}
                        </select>
                    ) : (
                        <div className="font-medium text-slate-800 mt-0.5">
                             {payer?.id === 'u1' ? 'You' : payer?.name}
                        </div>
                    )}
                </div>
                {isEditing && <ChevronRight className="w-4 h-4 text-slate-300" />}
            </div>

            <div className="grid grid-cols-2 divide-x divide-slate-100">
                {/* Date */}
                <div className="p-4">
                    <div className="flex items-center gap-2 mb-1">
                        <Calendar className="w-3 h-3 text-slate-400" />
                        <span className="text-xs text-slate-500 font-semibold uppercase">Date</span>
                    </div>
                    {isEditing ? (
                        <input 
                            type="date"
                            value={data.date}
                            onChange={(e) => updateData({ date: e.target.value })}
                            className="w-full bg-transparent text-sm font-medium text-slate-800 focus:outline-none"
                        />
                    ) : (
                        <div className="text-sm font-medium text-slate-800">{data.date}</div>
                    )}
                </div>
                {/* Category */}
                <div className="p-4">
                    <div className="flex items-center gap-2 mb-1">
                        <Tag className="w-3 h-3 text-slate-400" />
                        <span className="text-xs text-slate-500 font-semibold uppercase">Category</span>
                    </div>
                     {isEditing ? (
                        <input 
                            type="text"
                            value={data.category}
                            onChange={(e) => updateData({ category: e.target.value })}
                            className="w-full bg-transparent text-sm font-medium text-slate-800 focus:outline-none"
                        />
                    ) : (
                        <div className="text-sm font-medium text-slate-800">{data.category || 'General'}</div>
                    )}
                </div>
            </div>

            {/* Group (Static) */}
            <div className="flex items-center p-4 border-t border-slate-100 bg-slate-50/50">
                <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600 mr-3">
                    <Users className="w-4 h-4" />
                </div>
                <div className="flex-1">
                    <div className="text-xs text-slate-500 font-semibold uppercase">Group</div>
                    <div className="text-sm font-medium text-slate-800">Trip to Paris</div>
                </div>
            </div>
        </div>

        {/* --- SPLIT SUMMARY --- */}
        <div className="space-y-3 pb-8">
            <div className="flex items-center justify-between px-1">
                <h3 className="font-bold text-slate-800 flex items-center gap-2">
                    Split Breakdown
                    <span className="text-xs font-normal bg-slate-200 text-slate-600 px-2 py-0.5 rounded-full capitalize">
                        {data.splitType.toLowerCase()}
                    </span>
                </h3>
                {/* MODIFIED: Always show Edit Split button, but styled differently if read-only */}
                <button 
                    onClick={onEditSplit}
                    className={`text-sm font-medium flex items-center gap-1 px-3 py-1.5 rounded-lg transition-colors ${
                        isEditing 
                            ? 'text-indigo-600 hover:text-indigo-700 bg-indigo-50'
                            : 'text-slate-500 hover:text-slate-800 hover:bg-slate-100'
                    }`}
                >
                    <Pencil className="w-3 h-3" /> {isEditing ? 'Modify' : 'Edit Split'}
                </button>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden divide-y divide-slate-50">
                {members.filter(m => memberTotals[m.id] > 0).length === 0 && (
                     <div className="p-4 text-center text-slate-400 text-sm">No splits assigned yet.</div>
                )}
                
                {members.filter(m => memberTotals[m.id] > 0).map(member => (
                    <div key={member.id} className="flex items-center justify-between p-3">
                        <div className="flex items-center gap-3">
                             <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-500">
                                {member.avatar}
                            </div>
                            <span className="text-sm font-medium text-slate-700">{member.name}</span>
                        </div>
                        <span className="text-sm font-bold text-slate-900">€{memberTotals[member.id].toFixed(2)}</span>
                    </div>
                ))}
                
                {isEditing && !isValid && (
                    <div className="p-3 bg-red-50 flex items-center justify-between text-red-600">
                        <div className="flex items-center gap-2 text-xs font-semibold">
                            <AlertCircle className="w-4 h-4" /> Unassigned Amount
                        </div>
                        <span className="font-bold text-sm">€{unassigned.toFixed(2)}</span>
                    </div>
                )}
            </div>
        </div>

      </div>

      {/* --- FOOTER (Save Button) --- */}
      {isEditing && (
        <div className="p-4 bg-white border-t border-slate-200">
            <button 
                onClick={onSave}
                disabled={!isValid}
                className="w-full bg-slate-900 text-white font-bold py-4 rounded-xl shadow-lg hover:bg-black active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:bg-slate-400"
            >
                <Save className="w-5 h-5" /> Save Changes
            </button>
        </div>
      )}
    </div>
  );
};

export default EditExpenseScreen;