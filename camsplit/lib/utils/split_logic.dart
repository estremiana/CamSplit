import '../presentation/expense_creation_wizard/models/receipt_item.dart';

class SplitLogic {
  /// Distributes a total amount into [parts] number of chunks,
  /// handling any remainder by adding 0.01 to the first few chunks.
  static List<double> distributeAmount(double total, int parts) {
    if (parts <= 0) return [];
    if (parts == 1) return [total];

    // Calculate the base amount (floor to 2 decimal places)
    // e.g. 10.00 / 3 = 3.333... -> 3.33
    double baseAmount = (total / parts * 100).floorToDouble() / 100;

    // Calculate the total distributed so far
    double distributed = baseAmount * parts;

    // Calculate remainder (e.g. 10.00 - 9.99 = 0.01)
    // Round to avoid floating point errors like 0.009999999
    double remainder = (total - distributed);
    int remainderCents = (remainder * 100).round();

    List<double> result = List.filled(parts, baseAmount);

    // Distribute the remainder cents
    for (int i = 0; i < remainderCents; i++) {
      result[i] += 0.01;
    }

    // Fix precision for all elements
    return result.map((e) => double.parse(e.toStringAsFixed(2))).toList();
  }

  /// Calculates the cost per member for a given item.
  ///
  /// If [item.isCustomSplit] is false (simple split), it distributes the total price
  /// equally among assigned members with rounding handling.
  ///
  /// If [item.isCustomSplit] is true, it calculates cost based on assigned quantity.
  static Map<String, double> calculateItemCosts(ReceiptItem item) {
    Map<String, double> costs = {};
    
    if (item.assignments.isEmpty) return costs;

    if (!item.isCustomSplit) {
      // Simple split: divide total price among assigned members
      // Note: We use item.unitPrice * item.quantity for total price
      double totalPrice = item.unitPrice * item.quantity;
      
      // Get member IDs sorted to ensure deterministic distribution of remainder
      List<String> memberIds = item.assignments.keys.toList()..sort();
      
      List<double> distributedCosts = distributeAmount(totalPrice, memberIds.length);
      
      for (int i = 0; i < memberIds.length; i++) {
        costs[memberIds[i]] = distributedCosts[i];
      }
    } else {
      // Custom/Advanced split: use assigned quantity * unitPrice
      item.assignments.forEach((memberId, quantity) {
        costs[memberId] = double.parse((quantity * item.unitPrice).toStringAsFixed(2));
      });
    }

    return costs;
  }
}

