export interface Member {
  id: string;
  name: string;
  avatar: string; // URL or Initials
}

export enum SplitType {
  EQUAL = 'EQUAL',
  EXACT = 'EXACT',
  PERCENTAGE = 'PERCENTAGE',
  ITEMIZED = 'ITEMIZED'
}

export interface ReceiptItem {
  id: string; // generated unique id
  name: string;
  price: number; // Total price (unitPrice * quantity)
  quantity: number; // Total quantity available (e.g. 50)
  unitPrice: number; // Price per item
  assignments: Record<string, number>; // map of memberId -> quantity assigned
  isCustomSplit: boolean; // Explicit flag to lock Quick Mode if Advanced edits occur
}

export interface ExpenseData {
  amount: number;
  title: string;
  date: string;
  category: string;
  payerId: string;
  groupId: string;
  splitType: SplitType;
  // Map of memberId -> amount/percentage/share
  splitDetails: Record<string, number>; 
  // List of members involved in the split (for EQUAL mode, essentially who is checked)
  involvedMembers: string[];
  receiptImage?: string; // base64
  items: ReceiptItem[]; // List of scanned items
  notes?: string;
}

export interface ScannedReceiptData {
  total: number | null;
  merchant: string | null;
  date: string | null;
  category: string | null;
  items: { name: string; price: number; quantity?: number }[];
}