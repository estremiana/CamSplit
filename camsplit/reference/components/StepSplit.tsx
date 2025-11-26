import React, { useState, useEffect } from 'react';
import { Check, Receipt, Pencil, Trash2, Plus, Minus, X, Users, Split, UserPlus, MoreHorizontal, Settings2, ChevronDown, ChevronUp, Lock, RefreshCcw, Percent, Coins, AlertCircle } from 'lucide-react';
import { ExpenseData, Member, SplitType, ReceiptItem } from '../types';

interface Props {
  data: ExpenseData;
  members: Member[];
  updateData: (updates: Partial<ExpenseData>) => void;
  onBack: () => void;
  onSubmit: () => void;
}

const StepSplit: React.FC<Props> = ({ data, members, updateData, onBack, onSubmit }) => {
  // State for Inline Expansion (Quick Mode)
  const [expandedItemId, setExpandedItemId] = useState<string | null>(null);
  
  // State for Modal (Advanced Mode)
  const [activeModalItem, setActiveModalItem] = useState<ReceiptItem | null>(null);
  
  const [isEditingItems, setIsEditingItems] = useState(false);

  // Modal Internal State
  const [assignQty, setAssignQty] = useState(1);
  const [selectedMemberIds, setSelectedMemberIds] = useState<string[]>([]);

  // Reset modal state when opening a new item
  useEffect(() => {
    if (activeModalItem) {
        const remaining = activeModalItem.quantity - getAssignedCountForItem(activeModalItem);
        // Default to 1, or remaining if less than 1 (but > 0)
        setAssignQty(remaining > 0 ? (remaining < 1 ? remaining : 1) : 0);
        setSelectedMemberIds([]);
    }
  }, [activeModalItem]);

  // --- HELPERS ---

  const getAssignedCountForItem = (item: ReceiptItem) => {
    return Object.values(item.assignments).reduce((a, b) => a + b, 0);
  };

  const getItemizedTotalForMember = (memberId: string) => {
    let total = 0;
    data.items.forEach(item => {
        const qty = item.assignments[memberId] || 0;
        total += qty * item.unitPrice;
    });
    return total.toFixed(2);
  };

  const getUnassignedAmount = () => {
    let unassigned = 0;
    data.items.forEach(item => {
        const assignedCount = getAssignedCountForItem(item);
        unassigned += (item.quantity - assignedCount) * item.unitPrice;
    });
    return unassigned;
  };

  const getManualSplitTotal = () => {
    // Explicitly type accumulator and value to avoid 'unknown' type inference errors
    return Object.values(data.splitDetails).reduce((sum: number, val: number) => sum + (val || 0), 0);
  };

  const getRemainingManual = () => {
      if (data.splitType === SplitType.PERCENTAGE) {
          return 100 - getManualSplitTotal();
      }
      if (data.splitType === SplitType.EXACT) {
          return data.amount - getManualSplitTotal();
      }
      return 0;
  };

  const isSplitValid = () => {
      if (data.splitType === SplitType.ITEMIZED) {
          return getUnassignedAmount() < 0.05;
      }
      if (data.splitType === SplitType.PERCENTAGE) {
          return Math.abs(getRemainingManual()) < 0.1;
      }
      if (data.splitType === SplitType.EXACT) {
          return Math.abs(getRemainingManual()) < 0.05;
      }
      return true; // EQUAL is always valid
  };

  // --- SPLIT TYPE SWITCHING ---

  const handleSplitTypeChange = (type: SplitType) => {
      if (type === data.splitType) return;
      
      const updates: Partial<ExpenseData> = { splitType: type };

      // Initialize defaults for Manual Modes
      if (type === SplitType.PERCENTAGE || type === SplitType.EXACT) {
          const involved = data.involvedMembers.length > 0 ? data.involvedMembers : members.map(m => m.id);
          const count = involved.length;
          const newDetails: Record<string, number> = {};

          if (type === SplitType.PERCENTAGE) {
              const base = Math.floor(100 / count);
              const remainder = 100 - (base * count);
              involved.forEach((id, i) => {
                  newDetails[id] = base + (i < remainder ? 1 : 0);
              });
          } else {
              // Exact: Distribute amount evenly
              const base = data.amount / count;
              involved.forEach(id => {
                  newDetails[id] = parseFloat(base.toFixed(2));
              });
          }
          updates.splitDetails = newDetails;
          updates.involvedMembers = involved;
      }

      updateData(updates);
  };

  const handleManualValueChange = (memberId: string, valueStr: string) => {
      let value = parseFloat(valueStr);
      if (isNaN(value)) value = 0;
      
      const newDetails = { ...data.splitDetails, [memberId]: value };
      updateData({ splitDetails: newDetails });
  };

  const toggleMemberManual = (memberId: string) => {
      const isIncluded = data.involvedMembers.includes(memberId);
      let newInvolved = [...data.involvedMembers];
      let newDetails = { ...data.splitDetails };

      if (isIncluded) {
          newInvolved = newInvolved.filter(id => id !== memberId);
          delete newDetails[memberId];
      } else {
          newInvolved.push(memberId);
          newDetails[memberId] = 0;
      }
      updateData({ involvedMembers: newInvolved, splitDetails: newDetails });
  };

  // --- QUICK ASSIGN LOGIC (Inline) ---
  
  const handleQuickToggle = (memberId: string, item: ReceiptItem) => {
      if (item.isCustomSplit) return;

      const currentMemberIds = Object.keys(item.assignments);
      let newMemberIds: string[] = [];

      if (currentMemberIds.includes(memberId)) {
          newMemberIds = currentMemberIds.filter(id => id !== memberId);
      } else {
          newMemberIds = [...currentMemberIds, memberId];
      }

      const newAssignments: Record<string, number> = {};
      
      if (newMemberIds.length > 0) {
          const share = item.quantity / newMemberIds.length;
          newMemberIds.forEach(id => {
              newAssignments[id] = share;
          });
      }

      const newItems = data.items.map(i => i.id === item.id ? { ...i, assignments: newAssignments, isCustomSplit: false } : i);
      updateData({ items: newItems });
  };
  
  const clearItemAssignments = (itemId: string) => {
       const newItems = data.items.map(i => i.id === itemId ? { ...i, assignments: {}, isCustomSplit: false } : i);
       updateData({ items: newItems });
  };

  // --- ADVANCED ASSIGNMENT LOGIC (Modal) ---

  const commitAdvancedAssignment = () => {
      if (!activeModalItem || selectedMemberIds.length === 0 || assignQty <= 0) return;

      const items = [...data.items];
      const index = items.findIndex(i => i.id === activeModalItem.id);
      if (index === -1) return;

      const item = { ...items[index], assignments: { ...items[index].assignments }, isCustomSplit: true };
      const qtyPerPerson = assignQty / selectedMemberIds.length;

      selectedMemberIds.forEach(memberId => {
          const current = item.assignments[memberId] || 0;
          item.assignments[memberId] = current + qtyPerPerson;
      });

      items[index] = item;
      updateData({ items });
      setActiveModalItem(item);
      
      const newRemaining = item.quantity - getAssignedCountForItem(item);
      setAssignQty(newRemaining > 0 ? (newRemaining < 1 ? newRemaining : 1) : 0);
      setSelectedMemberIds([]);
  };

  const clearAssignmentForMember = (memberId: string) => {
      if (!activeModalItem) return;
      const items = [...data.items];
      const index = items.findIndex(i => i.id === activeModalItem.id);
      if (index === -1) return;

      const item = { ...items[index], assignments: { ...items[index].assignments }, isCustomSplit: true };
      delete item.assignments[memberId];

      items[index] = item;
      updateData({ items });
      setActiveModalItem(item);
  };

  const toggleModalMemberSelection = (id: string) => {
      if (selectedMemberIds.includes(id)) {
          setSelectedMemberIds(prev => prev.filter(m => m !== id));
      } else {
          setSelectedMemberIds(prev => [...prev, id]);
      }
  };

  // --- EDIT MODE Logic ---
  const updateItemDetails = (id: string, field: keyof ReceiptItem, value: any) => {
      const newItems = data.items.map(item => {
          if (item.id === id) {
              const updated = { ...item, [field]: value };
              if (field === 'unitPrice' || field === 'quantity') {
                  updated.price = updated.unitPrice * updated.quantity;
              }
              return updated;
          }
          return item;
      });
      updateData({ items: newItems });
  };

  const addNewItem = () => {
      const newItem: ReceiptItem = {
          id: `manual-${Date.now()}`,
          name: 'New Item',
          price: 0,
          unitPrice: 0,
          quantity: 1,
          assignments: {},
          isCustomSplit: false
      };
      updateData({ items: [...data.items, newItem] });
  };

  const deleteItem = (id: string) => {
      updateData({ items: data.items.filter(i => i.id !== id) });
  };

  const handleFinishEditing = () => {
      const newTotal = data.items.reduce((sum, item) => sum + (item.unitPrice * item.quantity), 0);
      updateData({ amount: newTotal });
      setIsEditingItems(false);
  };
  
  // --- EQUAL Logic Helper ---
  const toggleMemberEqual = (memberId: string) => {
    const currentInvolved = [...data.involvedMembers];
    if (currentInvolved.includes(memberId)) {
        if (currentInvolved.length > 1) { 
            updateData({ involvedMembers: currentInvolved.filter(id => id !== memberId) });
        }
    } else {
        updateData({ involvedMembers: [...currentInvolved, memberId] });
    }
  };

  const getEqualAmount = (memberId: string) => {
      if (data.involvedMembers.includes(memberId)) {
          return (data.amount / data.involvedMembers.length).toFixed(2);
      }
      return '0.00';
  };


  return (
    <div className="flex flex-col h-full animate-in fade-in slide-in-from-right-8 duration-500 relative">
      <div className="flex justify-between items-center mb-6">
        <button onClick={onBack} className="text-slate-500 hover:text-slate-700">Back</button>
        <span className="font-semibold text-slate-900">3 of 3</span>
        <div className="w-10"></div>
      </div>

      <div className="flex-1 flex flex-col overflow-hidden">
        <div className="mb-6 flex justify-between items-end">
            <div>
                <h2 className="text-2xl font-bold text-slate-800 mb-1">Split Options</h2>
                <p className="text-slate-500 text-sm">
                    {data.splitType === SplitType.ITEMIZED 
                    ? isEditingItems ? "Modify items, prices and quantities" : "Tap items to assign"
                    : `How should this €${data.amount.toFixed(2)} be shared?`
                    }
                </p>
            </div>
            {data.splitType === SplitType.ITEMIZED && !isEditingItems && (
                <button 
                    onClick={() => setIsEditingItems(true)}
                    className="text-indigo-600 text-sm font-medium flex items-center gap-1 hover:text-indigo-700"
                >
                    <Pencil className="w-3 h-3" /> Edit
                </button>
            )}
             {data.splitType === SplitType.ITEMIZED && isEditingItems && (
                <button 
                    onClick={handleFinishEditing}
                    className="text-green-600 text-sm font-medium flex items-center gap-1 hover:text-green-700"
                >
                    <Check className="w-3 h-3" /> Done
                </button>
            )}
        </div>

        {/* Tabs */}
        {!isEditingItems && (
            <div className="flex p-1 bg-slate-100 rounded-xl mb-6 flex-shrink-0">
                <button
                    onClick={() => handleSplitTypeChange(SplitType.EQUAL)}
                    className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all ${data.splitType === SplitType.EQUAL ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500'}`}
                >
                    Equal
                </button>
                <button
                    onClick={() => handleSplitTypeChange(SplitType.PERCENTAGE)}
                    className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all flex items-center justify-center gap-1 ${data.splitType === SplitType.PERCENTAGE ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500'}`}
                >
                    <Percent className="w-3 h-3" /> %
                </button>
                <button
                    onClick={() => handleSplitTypeChange(SplitType.EXACT)}
                    className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all flex items-center justify-center gap-1 ${data.splitType === SplitType.EXACT ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500'}`}
                >
                    <Coins className="w-3 h-3" /> Custom
                </button>
                <button
                    onClick={() => handleSplitTypeChange(SplitType.ITEMIZED)}
                    className={`flex-1 py-2 text-sm font-medium rounded-lg transition-all flex items-center justify-center gap-1 ${data.splitType === SplitType.ITEMIZED ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500'}`}
                >
                    <Receipt className="w-3 h-3" /> Items
                </button>
            </div>
        )}

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto pr-1 no-scrollbar pb-24">
            
            {/* --- ITEMIZED VIEW --- */}
            {data.splitType === SplitType.ITEMIZED ? (
                <div className="space-y-3">
                     {data.items.map((item) => {
                         const assignedCount = getAssignedCountForItem(item);
                         const isFullyAssigned = assignedCount >= item.quantity - 0.05;
                         const isExpanded = expandedItemId === item.id;
                         const isLocked = item.isCustomSplit;
                         
                         // --- EDIT MODE ROW ---
                         if (isEditingItems) {
                             return (
                                 <div key={item.id} className="flex flex-col bg-white border border-slate-200 rounded-xl p-3 gap-2">
                                     <div className="flex items-center gap-2">
                                         <input 
                                            value={item.name}
                                            onChange={(e) => updateItemDetails(item.id, 'name', e.target.value)}
                                            className="flex-1 bg-transparent border-b border-transparent focus:border-indigo-300 focus:outline-none text-slate-800 font-medium"
                                         />
                                          <button 
                                            onClick={() => deleteItem(item.id)}
                                            className="p-1 text-red-400 hover:bg-red-50 rounded"
                                         >
                                             <Trash2 className="w-4 h-4" />
                                         </button>
                                     </div>
                                     <div className="flex items-center gap-4 text-sm">
                                         <div className="flex items-center gap-1">
                                             <span className="text-slate-400 text-xs uppercase">Qty</span>
                                             <input 
                                                type="number"
                                                value={item.quantity}
                                                onChange={(e) => updateItemDetails(item.id, 'quantity', parseFloat(e.target.value) || 1)}
                                                className="w-12 bg-slate-50 rounded px-1 py-0.5 text-center font-medium"
                                             />
                                         </div>
                                         <div className="flex items-center gap-1">
                                             <span className="text-slate-400 text-xs uppercase">Unit €</span>
                                             <input 
                                                type="number"
                                                value={item.unitPrice}
                                                onChange={(e) => updateItemDetails(item.id, 'unitPrice', parseFloat(e.target.value) || 0)}
                                                className="w-16 bg-slate-50 rounded px-1 py-0.5 text-center font-medium"
                                             />
                                         </div>
                                         <div className="ml-auto font-semibold text-slate-700">
                                             €{(item.quantity * item.unitPrice).toFixed(2)}
                                         </div>
                                     </div>
                                 </div>
                             )
                         }

                         // --- NORMAL ROW ---
                         return (
                            <div key={item.id} className="overflow-hidden rounded-xl bg-white border border-slate-200 transition-all duration-300">
                                <button 
                                    onClick={() => setExpandedItemId(isExpanded ? null : item.id)}
                                    className={`w-full text-left p-3 flex items-center justify-between group transition-colors ${
                                        isExpanded ? 'bg-indigo-50/50' : 'bg-white hover:bg-slate-50'
                                    } ${isFullyAssigned && !isExpanded ? 'bg-green-50/30 border-green-100' : ''}`}
                                >
                                    <div>
                                        <div className="flex items-center gap-2">
                                            <span className={`font-medium ${isFullyAssigned ? 'text-green-800' : 'text-slate-800'}`}>{item.name}</span>
                                            {item.quantity > 1 && (
                                                <span className="bg-slate-100 text-slate-600 text-xs px-1.5 py-0.5 rounded font-bold">x{item.quantity}</span>
                                            )}
                                        </div>
                                        <div className="text-xs text-slate-500 mt-1 flex items-center gap-2">
                                            <span>€{item.unitPrice.toFixed(2)} each</span>
                                            {!isExpanded && (
                                                <>
                                                    <span className="w-1 h-1 bg-slate-300 rounded-full"></span>
                                                    {isLocked ? (
                                                         <span className="text-amber-600 font-medium flex items-center gap-1">
                                                             <Lock className="w-3 h-3" /> Custom Split
                                                         </span>
                                                    ) : (
                                                        <span className={isFullyAssigned ? 'text-green-600 font-medium' : 'text-indigo-600'}>
                                                            {assignedCount % 1 === 0 ? assignedCount : assignedCount.toFixed(1)}/{item.quantity} assigned
                                                        </span>
                                                    )}
                                                </>
                                            )}
                                        </div>
                                    </div>
                                    <div className="text-right flex items-center gap-3">
                                        <div className="font-semibold text-slate-900">€{item.price.toFixed(2)}</div>
                                        {isExpanded ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
                                    </div>
                                </button>
                                
                                {/* --- INLINE QUICK ASSIGN PANEL --- */}
                                {isExpanded && (
                                    <div className="p-3 bg-indigo-50/30 border-t border-indigo-100/50 animate-in slide-in-from-top-2 duration-200 relative">
                                        
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Quick Split (Equal)</span>
                                            <span className={`text-[10px] font-bold uppercase tracking-wider ${isFullyAssigned ? 'text-green-600' : 'text-indigo-600'}`}>
                                                 {assignedCount % 1 === 0 ? assignedCount : assignedCount.toFixed(1)} / {item.quantity} Assigned
                                            </span>
                                        </div>
                                        
                                        {/* Avatar Grid */}
                                        <div className={`grid grid-cols-6 gap-2 transition-opacity duration-200 ${isLocked ? 'opacity-20 pointer-events-none' : 'opacity-100'}`}>
                                            {members.map(member => {
                                                const qty = item.assignments[member.id] || 0;
                                                const isAssigned = qty > 0;
                                                return (
                                                    <button 
                                                        key={member.id}
                                                        onClick={() => handleQuickToggle(member.id, item)}
                                                        className="flex flex-col items-center gap-1 group"
                                                    >
                                                        <div className={`w-10 h-10 rounded-full flex items-center justify-center text-xs font-bold border-2 transition-all relative ${
                                                            isAssigned 
                                                            ? 'border-indigo-500 bg-indigo-50 text-indigo-700 shadow-sm scale-105' 
                                                            : 'border-transparent bg-white text-slate-400 hover:border-slate-200'
                                                        }`}>
                                                            {member.avatar.startsWith('http') ? <img src={member.avatar} className="w-full h-full rounded-full"/> : member.avatar}
                                                            {isAssigned && (
                                                                <div className="absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 rounded-full border border-white flex items-center justify-center text-[8px] text-white">
                                                                    {qty % 1 === 0 ? qty : qty.toFixed(1)}
                                                                </div>
                                                            )}
                                                        </div>
                                                        <span className={`text-[9px] truncate w-full text-center ${isAssigned ? 'font-semibold text-indigo-700' : 'text-slate-400'}`}>
                                                            {member.name.split(' ')[0]}
                                                        </span>
                                                    </button>
                                                )
                                            })}
                                        </div>

                                        {/* Locked Overlay */}
                                        {isLocked && (
                                            <div className="absolute inset-0 flex items-center justify-center z-10 pointer-events-none">
                                                <div className="bg-white/90 backdrop-blur-sm border border-slate-200 shadow-lg px-4 py-2 rounded-xl flex items-center gap-3 pointer-events-auto">
                                                    <div className="text-xs text-slate-600 font-medium flex items-center gap-1">
                                                        <Lock className="w-3 h-3 text-amber-500" />
                                                        Custom Split Active
                                                    </div>
                                                    <button 
                                                        onClick={() => clearItemAssignments(item.id)}
                                                        className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2 py-1 rounded hover:bg-indigo-100 flex items-center gap-1"
                                                    >
                                                        <RefreshCcw className="w-3 h-3" />
                                                        Reset
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                        
                                        <div className="mt-4 pt-3 border-t border-slate-100 flex justify-end">
                                             <button 
                                                onClick={() => setActiveModalItem(item)}
                                                className="flex items-center gap-2 text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 px-3 py-2 rounded-lg transition-colors"
                                             >
                                                 <Settings2 className="w-3 h-3" />
                                                 Advanced / Partial Split
                                             </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                         );
                     })}

                    {isEditingItems && (
                        <button 
                            onClick={addNewItem}
                            className="w-full py-3 border-2 border-dashed border-slate-300 rounded-xl text-slate-500 font-medium hover:border-indigo-400 hover:text-indigo-500 transition-colors flex items-center justify-center gap-2"
                        >
                            <Plus className="w-4 h-4" /> Add Item
                        </button>
                    )}

                    {!isEditingItems && (
                        <div className="bg-slate-50 rounded-2xl p-4 space-y-2 mt-4 pb-20">
                            <h3 className="text-sm font-semibold text-slate-500 uppercase">Summary</h3>
                            {members.filter(m => getItemizedTotalForMember(m.id) !== '0.00').map(m => (
                                <div key={m.id} className="flex justify-between text-sm">
                                    <span className="text-slate-600">{m.name}</span>
                                    <span className="font-medium text-slate-900">€{getItemizedTotalForMember(m.id)}</span>
                                </div>
                            ))}
                            {getUnassignedAmount() > 0.01 && (
                                <div className="flex justify-between text-sm text-red-500 pt-2 border-t border-slate-200 mt-2">
                                    <span>Unassigned</span>
                                    <span className="font-bold">€{getUnassignedAmount().toFixed(2)}</span>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            ) : (
                /* --- STANDARD EQUAL / PERCENTAGE / EXACT VIEW --- */
                <div className="space-y-3 pb-20">
                    {/* Header for Remaining (Manual modes only) */}
                    {(data.splitType === SplitType.PERCENTAGE || data.splitType === SplitType.EXACT) && (
                        <div className={`mb-4 text-center p-2 rounded-lg text-sm font-medium transition-colors ${Math.abs(getRemainingManual()) < 0.1 ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>
                             {data.splitType === SplitType.PERCENTAGE 
                                ? `${getRemainingManual().toFixed(1)}% remaining`
                                : `€${getRemainingManual().toFixed(2)} remaining`
                             }
                        </div>
                    )}

                    {members.map(member => {
                        const isSelected = data.involvedMembers.includes(member.id);
                        const equalAmount = getEqualAmount(member.id);

                        return (
                            <div 
                                key={member.id}
                                className={`flex items-center justify-between p-3 rounded-2xl border transition-all ${
                                    isSelected 
                                    ? 'bg-white border-indigo-200 shadow-sm' 
                                    : 'bg-slate-50 border-transparent opacity-60'
                                }`}
                            >
                                {/* Left Side: Click to toggle involved */}
                                <div 
                                    className="flex items-center gap-3 cursor-pointer flex-1"
                                    onClick={() => {
                                        if (data.splitType === SplitType.EQUAL) toggleMemberEqual(member.id);
                                        else toggleMemberManual(member.id);
                                    }}
                                >
                                    <div className="relative">
                                        {member.avatar.startsWith('http') ? (
                                            <img src={member.avatar} alt={member.name} className="w-10 h-10 rounded-full object-cover" />
                                        ) : (
                                            <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm ${isSelected ? 'bg-indigo-100 text-indigo-600' : 'bg-slate-200 text-slate-500'}`}>
                                                {member.avatar}
                                            </div>
                                        )}
                                        {isSelected && (
                                            <div className="absolute -bottom-1 -right-1 bg-indigo-500 rounded-full p-0.5 border-2 border-white">
                                                <Check className="w-2 h-2 text-white" />
                                            </div>
                                        )}
                                    </div>
                                    <div>
                                        <p className={`font-medium ${isSelected ? 'text-slate-900' : 'text-slate-500'}`}>{member.name}</p>
                                        {isSelected && data.splitType === SplitType.EQUAL && (
                                            <p className="text-xs text-indigo-500">Pays €{equalAmount}</p>
                                        )}
                                    </div>
                                </div>

                                {/* Right Side: Input or Display */}
                                {data.splitType === SplitType.EQUAL ? (
                                    <div className="w-6 h-6"></div> // Spacer
                                ) : (
                                    <div className={`flex items-center gap-1 bg-slate-50 rounded-lg px-2 py-1 border focus-within:ring-2 focus-within:ring-indigo-500/20 focus-within:border-indigo-400 transition-all ${isSelected ? 'opacity-100 border-slate-200' : 'opacity-40 border-transparent pointer-events-none'}`}>
                                        <input 
                                            type="number"
                                            value={isSelected ? (data.splitDetails[member.id] || '') : ''}
                                            onChange={(e) => handleManualValueChange(member.id, e.target.value)}
                                            placeholder="0"
                                            disabled={!isSelected}
                                            className="w-16 bg-transparent text-right font-semibold text-slate-700 focus:outline-none"
                                        />
                                        <span className="text-slate-400 text-sm font-medium">
                                            {data.splitType === SplitType.PERCENTAGE ? '%' : '€'}
                                        </span>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
      </div>

      {/* Floating Action Button */}
      {!isEditingItems && !activeModalItem && (
        <div className="absolute bottom-6 left-0 right-0 px-6 bg-gradient-to-t from-slate-50 pt-4 pointer-events-none">
            <div className="pointer-events-auto">
                {!isSplitValid() && (
                    <div className="mb-2 bg-red-100 text-red-700 text-xs font-semibold px-4 py-2 rounded-xl flex items-center gap-2 justify-center shadow-sm">
                        <AlertCircle className="w-4 h-4" />
                        {data.splitType === SplitType.ITEMIZED 
                            ? "Assign all items before continuing" 
                            : `Total mismatch. Adjust ${data.splitType === SplitType.PERCENTAGE ? '%' : 'amount'} to match total.`
                        }
                    </div>
                )}
                <button 
                    onClick={onSubmit}
                    disabled={!isSplitValid()}
                    className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-4 rounded-2xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:bg-slate-400 disabled:shadow-none"
                >
                    <Check className="w-5 h-5" />
                    Create Expense
                </button>
            </div>
        </div>
      )}

      {/* --- ADVANCED ASSIGNMENT MODAL (POPUP) --- */}
      {activeModalItem && (
          <div className="absolute inset-0 z-50 flex flex-col justify-end bg-black/25 animate-in fade-in duration-200">
              {/* Backdrop Click */}
              <div className="absolute inset-0" onClick={() => setActiveModalItem(null)}></div>
              
              <div className="bg-white w-full rounded-t-3xl shadow-2xl flex flex-col max-h-[90%] animate-in slide-in-from-bottom duration-300 relative z-50">
                  {/* Header */}
                  <div className="p-5 border-b border-slate-100 flex items-start justify-between flex-shrink-0 bg-slate-50/50 rounded-t-3xl">
                      <div>
                          <h3 className="font-bold text-lg text-slate-900 leading-tight">{activeModalItem.name}</h3>
                          <div className="text-sm font-medium text-indigo-600 mt-1">
                               {activeModalItem.quantity - getAssignedCountForItem(activeModalItem)} / {activeModalItem.quantity} Remaining
                          </div>
                      </div>
                      <button onClick={() => setActiveModalItem(null)} className="p-2 bg-slate-200 rounded-full hover:bg-slate-300 text-slate-600">
                          <X className="w-5 h-5" />
                      </button>
                  </div>
                  
                  <div className="flex-1 overflow-y-auto p-5 space-y-8">
                      
                      {/* 1. BUILDER: Quantity & People */}
                      <div className="space-y-6">
                        {/* Quantity Selector */}
                        <div className="flex items-center justify-between">
                            <span className="text-sm font-bold uppercase tracking-wide text-slate-400">Quantity to Assign</span>
                            <div className="flex items-center gap-3 bg-slate-100 rounded-xl p-1">
                                <button 
                                    onClick={() => setAssignQty(Math.max(0.5, assignQty - 0.5))}
                                    className="w-10 h-10 rounded-lg bg-white shadow-sm flex items-center justify-center text-slate-600 active:scale-95 transition-transform"
                                >
                                    <Minus className="w-4 h-4" />
                                </button>
                                <input 
                                    type="number"
                                    value={assignQty}
                                    onChange={(e) => setAssignQty(parseFloat(e.target.value) || 0)}
                                    className="w-16 text-center bg-transparent font-bold text-xl text-slate-800 focus:outline-none"
                                />
                                <button 
                                    onClick={() => setAssignQty(assignQty + 0.5)}
                                    className="w-10 h-10 rounded-lg bg-white shadow-sm flex items-center justify-center text-slate-600 active:scale-95 transition-transform"
                                >
                                    <Plus className="w-4 h-4" />
                                </button>
                            </div>
                        </div>

                        {/* People Grid */}
                        <div className="space-y-3">
                            <div className="flex justify-between items-center">
                                <span className="text-sm font-bold uppercase tracking-wide text-slate-400">Select Members</span>
                                {selectedMemberIds.length > 0 && (
                                    <button onClick={() => setSelectedMemberIds([])} className="text-xs font-medium text-slate-400 hover:text-slate-600">
                                        Clear
                                    </button>
                                )}
                            </div>
                            <div className="grid grid-cols-5 gap-3">
                                {members.map(member => {
                                    const isSelected = selectedMemberIds.includes(member.id);
                                    return (
                                        <button 
                                            key={member.id}
                                            onClick={() => toggleModalMemberSelection(member.id)}
                                            className="flex flex-col items-center gap-1 group"
                                        >
                                            <div className={`w-12 h-12 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all relative ${
                                                isSelected 
                                                ? 'border-indigo-500 bg-indigo-50 text-indigo-700 shadow-md scale-105' 
                                                : 'border-transparent bg-slate-100 text-slate-500 group-hover:bg-slate-200'
                                            }`}>
                                                {member.avatar.startsWith('http') ? <img src={member.avatar} className="w-full h-full rounded-full"/> : member.avatar}
                                                {isSelected && (
                                                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-indigo-500 rounded-full border-2 border-white flex items-center justify-center">
                                                        <Check className="w-3 h-3 text-white" />
                                                    </div>
                                                )}
                                            </div>
                                            <span className={`text-[10px] font-medium truncate w-full text-center ${isSelected ? 'text-indigo-600' : 'text-slate-400'}`}>
                                                {member.name.split(' ')[0]}
                                            </span>
                                        </button>
                                    )
                                })}
                            </div>
                        </div>
                      </div>

                      {/* Action Button */}
                      <button 
                          onClick={commitAdvancedAssignment}
                          disabled={selectedMemberIds.length === 0 || assignQty <= 0}
                          className="w-full py-4 rounded-xl bg-indigo-600 text-white font-bold text-lg shadow-lg shadow-indigo-200 hover:bg-indigo-700 active:scale-[0.98] transition-all disabled:opacity-50 disabled:shadow-none disabled:bg-slate-300 flex items-center justify-center gap-2"
                      >
                          {selectedMemberIds.length === 0 
                              ? "Select members above" 
                              : selectedMemberIds.length === 1 
                                  ? `Assign ${assignQty} to ${members.find(m => m.id === selectedMemberIds[0])?.name.split(' ')[0]}` 
                                  : `Split ${assignQty} between ${selectedMemberIds.length} people`
                          }
                      </button>

                      {/* 2. HISTORY LIST */}
                      <div className="border-t border-slate-100 pt-6">
                           <h4 className="text-sm font-bold uppercase tracking-wide text-slate-400 mb-4">Current Assignments</h4>
                           <div className="space-y-3">
                                {Object.entries(activeModalItem.assignments).length === 0 ? (
                                    <p className="text-center text-slate-400 text-sm py-2">No one assigned yet.</p>
                                ) : (
                                    Object.entries(activeModalItem.assignments).map(([memberId, qty]) => {
                                        const member = members.find(m => m.id === memberId);
                                        const quantity = Number(qty);
                                        if(!member) return null;
                                        return (
                                            <div key={memberId} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-8 h-8 rounded-full bg-white border border-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">
                                                        {member.avatar}
                                                    </div>
                                                    <div className="font-medium text-slate-700">
                                                        {member.name}
                                                    </div>
                                                </div>
                                                <div className="flex items-center gap-4">
                                                    <div className="text-right">
                                                        <div className="font-bold text-slate-900">{quantity % 1 === 0 ? quantity : quantity.toFixed(1)} items</div>
                                                        <div className="text-xs text-slate-500">€{(quantity * activeModalItem.unitPrice).toFixed(2)}</div>
                                                    </div>
                                                    <button 
                                                        onClick={() => clearAssignmentForMember(memberId)}
                                                        className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                                                    >
                                                        <Trash2 className="w-4 h-4" />
                                                    </button>
                                                </div>
                                            </div>
                                        )
                                    })
                                )}
                           </div>
                      </div>
                  </div>
              </div>
          </div>
      )}
    </div>
  );
};

export default StepSplit;