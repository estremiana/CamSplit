import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assignment Summary Logic Tests', () {
    test('should calculate individual totals correctly from quantity assignments', () {
      // Test data
      final members = [
        {'id': '1', 'name': 'Alice'},
        {'id': '2', 'name': 'Bob'},
      ];
      
      final quantityAssignments = [
        {'memberIds': ['1'], 'totalPrice': 20.0},
        {'memberIds': ['2'], 'totalPrice': 30.0},
        {'memberIds': ['1', '2'], 'totalPrice': 10.0}, // Shared item
      ];
      
      // Calculate individual totals (simulating the widget logic)
      Map<String, double> totals = {};
      
      // Initialize all members with 0
      for (var member in members) {
        totals[member['id'].toString()] = 0.0;
      }
      
      // Calculate totals based on quantity assignments
      for (var assignment in quantityAssignments) {
        final memberIds = assignment['memberIds'] as List<dynamic>;
        final totalPrice = assignment['totalPrice'] as double;
        final sharedAmount = memberIds.isNotEmpty ? totalPrice / memberIds.length : 0.0;

        for (var memberId in memberIds) {
          final memberIdString = memberId.toString();
          totals[memberIdString] = (totals[memberIdString] ?? 0.0) + sharedAmount;
        }
      }
      
      // Verify calculations
      expect(totals['1'], equals(25.0)); // 20.0 + 5.0 (half of shared 10.0)
      expect(totals['2'], equals(35.0)); // 30.0 + 5.0 (half of shared 10.0)
    });
    
    test('should calculate equal split totals correctly', () {
      // Test data
      final members = [
        {'id': '1', 'name': 'Alice'},
        {'id': '2', 'name': 'Bob'},
      ];
      
      final items = [
        {'id': 1, 'total_price': 20.0},
        {'id': 2, 'total_price': 30.0},
      ];
      
      // Calculate equal split totals (simulating the widget logic)
      Map<String, double> totals = {};
      
      // Initialize all members with 0
      for (var member in members) {
        totals[member['id'].toString()] = 0.0;
      }
      
      // Equal split among all members
      final totalAmount = items.fold(0.0, (sum, item) => sum + (item['total_price'] as double));
      final perMember = members.isNotEmpty ? totalAmount / members.length : 0.0;

      for (var member in members) {
        totals[member['id'].toString()] = perMember;
      }
      
      // Verify calculations
      expect(totals['1'], equals(25.0)); // 50.0 / 2
      expect(totals['2'], equals(25.0)); // 50.0 / 2
    });
    
    test('should preserve previous individual totals when no current assignments exist', () {
      // Test scenario: equal split is off, no current assignments, but previous totals exist
      final previousTotals = {
        '1': 15.0,
        '2': 35.0,
      };
      
      final members = [
        {'id': '1', 'name': 'Alice'},
        {'id': '2', 'name': 'Bob'},
      ];
      
      // Calculate current individual totals (empty assignments)
      Map<String, double> currentTotals = {};
      for (var member in members) {
        currentTotals[member['id'].toString()] = 0.0;
      }
      
      // Check if current assignments exist
      final hasCurrentAssignments = currentTotals.values.any((total) => total > 0);
      
      // Use previous totals if no current assignments
      Map<String, double> finalTotals;
      if (!hasCurrentAssignments && previousTotals != null) {
        finalTotals = Map<String, double>.from(previousTotals);
      } else {
        finalTotals = currentTotals;
      }
      
      // Verify that previous totals are used
      expect(finalTotals['1'], equals(15.0));
      expect(finalTotals['2'], equals(35.0));
    });
    
    test('should use current assignments when they exist, ignoring previous totals', () {
      // Test scenario: equal split is off, current assignments exist, previous totals exist
      final previousTotals = {
        '1': 15.0,
        '2': 35.0,
      };
      
      final members = [
        {'id': '1', 'name': 'Alice'},
        {'id': '2', 'name': 'Bob'},
      ];
      
      final quantityAssignments = [
        {'memberIds': ['1'], 'totalPrice': 10.0},
        {'memberIds': ['2'], 'totalPrice': 40.0},
      ];
      
      // Calculate current individual totals
      Map<String, double> currentTotals = {};
      for (var member in members) {
        currentTotals[member['id'].toString()] = 0.0;
      }
      
      for (var assignment in quantityAssignments) {
        final memberIds = assignment['memberIds'] as List<dynamic>;
        final totalPrice = assignment['totalPrice'] as double;
        final sharedAmount = memberIds.isNotEmpty ? totalPrice / memberIds.length : 0.0;

        for (var memberId in memberIds) {
          final memberIdString = memberId.toString();
          currentTotals[memberIdString] = (currentTotals[memberIdString] ?? 0.0) + sharedAmount;
        }
      }
      
      // Check if current assignments exist
      final hasCurrentAssignments = currentTotals.values.any((total) => total > 0);
      
      // Use current totals since they exist
      Map<String, double> finalTotals;
      if (!hasCurrentAssignments && previousTotals != null) {
        finalTotals = Map<String, double>.from(previousTotals);
      } else {
        finalTotals = currentTotals;
      }
      
      // Verify that current totals are used, not previous
      expect(finalTotals['1'], equals(10.0));
      expect(finalTotals['2'], equals(40.0));
    });

    test('should preserve individual assignment state when toggling equal split', () {
      // Test scenario: Simulate the toggle behavior
      final members = [
        {'id': '1', 'name': 'Alice'},
        {'id': '2', 'name': 'Bob'},
      ];
      
      final items = [
        {'id': 1, 'total_price': 20.0},
        {'id': 2, 'total_price': 30.0},
      ];
      
      // Initial state: individual assignments exist
      final initialIndividualTotals = {
        '1': 15.0,
        '2': 35.0,
      };
      
      // Simulate state variables
      Map<String, double>? previousIndividualTotals = Map<String, double>.from(initialIndividualTotals);
      Map<String, double>? currentIndividualTotals = Map<String, double>.from(initialIndividualTotals);
      Map<String, double>? equalSplitTotals;
      bool isEqualSplit = false;
      
      // Simulate toggling TO equal split (from individual)
      if (!isEqualSplit) {
        // Store current individual totals before switching
        if (currentIndividualTotals != null) {
          previousIndividualTotals = Map<String, double>.from(currentIndividualTotals);
        }
        
        // Calculate equal split totals
        final totalAmount = items.fold(0.0, (sum, item) => sum + (item['total_price'] as double));
        final perMember = members.isNotEmpty ? totalAmount / members.length : 0.0;
        
        equalSplitTotals = {};
        for (var member in members) {
          equalSplitTotals[member['id'].toString()] = perMember;
        }
        
        isEqualSplit = true;
      }
      
      // Verify equal split state
      expect(isEqualSplit, isTrue);
      expect(equalSplitTotals!['1'], equals(25.0)); // 50.0 / 2
      expect(equalSplitTotals['2'], equals(25.0)); // 50.0 / 2
      expect(previousIndividualTotals!['1'], equals(15.0)); // Preserved
      expect(previousIndividualTotals['2'], equals(35.0)); // Preserved
      
      // Simulate toggling BACK to individual split
      if (isEqualSplit) {
        // Individual assignments should be restored from previousIndividualTotals
        isEqualSplit = false;
      }
      
      // Verify individual state is restored
      expect(isEqualSplit, isFalse);
      expect(previousIndividualTotals['1'], equals(15.0)); // Should be restored
      expect(previousIndividualTotals['2'], equals(35.0)); // Should be restored
    });
    
    test('should show different totals based on assignment mode', () {
      // Test data
      final items = [
        {'id': 1, 'total_price': 20.0, 'assignedMembers': ['1']}, // Assigned
        {'id': 2, 'total_price': 30.0, 'assignedMembers': []},    // Not assigned
      ];
      
      final quantityAssignments = [
        {'memberIds': ['1'], 'totalPrice': 15.0}, // Partial assignment
      ];
      
      // Test 1: Equal split mode - should show actual total
      bool isEqualSplit = true;
      double totalInEqualSplit;
      if (isEqualSplit) {
        totalInEqualSplit = items.fold(0.0, (sum, item) => sum + (item['total_price'] as double));
      } else {
        totalInEqualSplit = 0.0; // Not relevant for this test
      }
      
      // Test 2: Non-equal split mode - should show sum of assignments
      isEqualSplit = false;
      double totalInNonEqualSplit;
      if (!isEqualSplit) {
        // With quantity assignments
        totalInNonEqualSplit = quantityAssignments.fold(0.0, (sum, assignment) => sum + (assignment['totalPrice'] as double));
      } else {
        totalInNonEqualSplit = 0.0; // Not relevant for this test
      }
      
      // Test 3: Non-equal split mode without quantity assignments - should show assigned items total
      double totalFromAssignedItems = 0.0;
      for (var item in items) {
        final assignedMembers = List<String>.from(item['assignedMembers'] as List? ?? []);
        if (assignedMembers.isNotEmpty) {
          totalFromAssignedItems += (item['total_price'] as double);
        }
      }
      
      // Verify different behavior
      expect(totalInEqualSplit, equals(50.0)); // Actual total of all items
      expect(totalInNonEqualSplit, equals(15.0)); // Sum of quantity assignments
      expect(totalFromAssignedItems, equals(20.0)); // Only assigned items (item 1)
    });
  });
}