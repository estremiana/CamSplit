import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 24: Modal displays remaining quantity
/// Feature: expense-wizard-creation, Property 25: Quantity adjustment updates value
/// Feature: expense-wizard-creation, Property 26: Avatar toggle in modal
/// Feature: expense-wizard-creation, Property 27: Assignment button text reflects selection
/// Validates: Requirements 6.3, 6.6, 6.7, 6.8
///
/// Property 24: For any item opened in AdvancedModal, the displayed remaining quantity
/// should equal (total quantity - assigned quantity)
///
/// Property 25: For any quantity adjustment in AdvancedModal, the quantity to assign
/// value should update accordingly
///
/// Property 26: For any member avatar tapped in AdvancedModal, that member's selection
/// state should toggle
///
/// Property 27: For any selection state in AdvancedModal, the button text should
/// accurately describe the assignment action

// Helper class to simulate modal state
class ModalState {
  double assignQty;
  Set<String> selectedMemberIds;

  ModalState({
    required this.assignQty,
    Set<String>? selectedMemberIds,
  }) : selectedMemberIds = selectedMemberIds ?? {};

  ModalState copyWith({
    double? assignQty,
    Set<String>? selectedMemberIds,
  }) {
    return ModalState(
      assignQty: assignQty ?? this.assignQty,
      selectedMemberIds: selectedMemberIds ?? Set<String>.from(this.selectedMemberIds),
    );
  }
}

// Helper function to simulate quantity increment
ModalState incrementQuantity(ModalState state, ReceiptItem item) {
  final remainingQty = item.getRemainingCount();
  if (state.assignQty < remainingQty) {
    return state.copyWith(assignQty: state.assignQty + 1);
  }
  return state;
}

// Helper function to simulate quantity decrement
ModalState decrementQuantity(ModalState state) {
  if (state.assignQty > 0.5) {
    final newQty = state.assignQty - 1;
    return state.copyWith(assignQty: newQty < 0.5 ? 0.5 : newQty);
  }
  return state;
}

// Helper function to simulate member toggle
ModalState toggleMember(ModalState state, String memberId) {
  final newSelected = Set<String>.from(state.selectedMemberIds);
  if (newSelected.contains(memberId)) {
    newSelected.remove(memberId);
  } else {
    newSelected.add(memberId);
  }
  return state.copyWith(selectedMemberIds: newSelected);
}

// Helper function to get action button text
String getActionButtonText(ModalState state) {
  if (state.selectedMemberIds.isEmpty) {
    return 'Select members to assign';
  }

  final qtyText = state.assignQty.toStringAsFixed(
    state.assignQty.truncateToDouble() == state.assignQty ? 0 : 1,
  );
  final memberCount = state.selectedMemberIds.length;

  return 'Split $qtyText between $memberCount ${memberCount == 1 ? 'person' : 'people'}';
}

// Helper function to create assignment
Map<String, double> createAssignment(
  ReceiptItem item,
  ModalState state,
) {
  if (state.selectedMemberIds.isEmpty) {
    return Map<String, double>.from(item.assignments);
  }

  final sharePerPerson = state.assignQty / state.selectedMemberIds.length;
  final newAssignments = Map<String, double>.from(item.assignments);

  for (final memberId in state.selectedMemberIds) {
    newAssignments[memberId] = (newAssignments[memberId] ?? 0.0) + sharePerPerson;
  }

  return newAssignments;
}

void main() {
  final faker = Faker();
  final random = Random();

  group('Advanced Modal Property Tests', () {
    // Helper function to generate random ReceiptItem
    ReceiptItem generateRandomReceiptItem({
      String? id,
      String? name,
      double? quantity,
      double? unitPrice,
      Map<String, double>? assignments,
      bool? isCustomSplit,
    }) {
      final qty = quantity ?? (random.nextDouble() * 20) + 1;
      final price = unitPrice ?? (random.nextDouble() * 100) + 1;

      return ReceiptItem(
        id: id ?? faker.guid.guid(),
        name: name ?? faker.food.dish(),
        quantity: qty,
        unitPrice: price,
        price: qty * price,
        assignments: assignments ?? {},
        isCustomSplit: isCustomSplit ?? false,
      );
    }

    /// Property 24: Modal displays remaining quantity
    /// For any item, remaining quantity = total quantity - assigned quantity
    test('Property 24: Remaining quantity equals total minus assigned', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;
        final assignedQty = random.nextDouble() * totalQty;

        // Create assignments that sum to assignedQty
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};
        final sharePerMember = assignedQty / memberCount;

        for (int j = 0; j < memberCount; j++) {
          assignments['member_$j'] = sharePerMember;
        }

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: assignments,
        );

        final remainingQty = item.getRemainingCount();
        final expectedRemaining = totalQty - assignedQty;

        expect(
          remainingQty,
          closeTo(expectedRemaining, 0.01),
          reason: 'Remaining quantity should equal total minus assigned',
        );
      }
    });

    test('Property 24: Remaining quantity is zero when fully assigned', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {'member_1': totalQty},
        );

        final remainingQty = item.getRemainingCount();

        expect(
          remainingQty,
          closeTo(0.0, 0.01),
          reason: 'Remaining should be zero when fully assigned',
        );
      }
    });

    test('Property 24: Remaining quantity equals total when nothing assigned', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        final remainingQty = item.getRemainingCount();

        expect(
          remainingQty,
          closeTo(totalQty, 0.01),
          reason: 'Remaining should equal total when nothing assigned',
        );
      }
    });

    test('Property 24: Remaining quantity updates after partial assignment', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;
        final partialQty = random.nextDouble() * totalQty * 0.5; // Assign up to 50%

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {'member_1': partialQty},
        );

        final remainingQty = item.getRemainingCount();
        final expectedRemaining = totalQty - partialQty;

        expect(
          remainingQty,
          closeTo(expectedRemaining, 0.01),
          reason: 'Remaining should reflect partial assignment',
        );
      }
    });

    /// Property 25: Quantity adjustment updates value
    /// For any quantity adjustment, the value should update accordingly
    test('Property 25: Increment increases quantity by 1', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5; // Ensure room to increment
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        final initialQty = random.nextDouble() * (totalQty - 2) + 1;
        var state = ModalState(assignQty: initialQty);

        final updated = incrementQuantity(state, item);

        expect(
          updated.assignQty,
          closeTo(initialQty + 1, 0.01),
          reason: 'Increment should increase quantity by 1',
        );
      }
    });

    test('Property 25: Increment does not exceed remaining quantity', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        final remainingQty = item.getRemainingCount();
        var state = ModalState(assignQty: remainingQty);

        // Try to increment beyond remaining
        final updated = incrementQuantity(state, item);

        expect(
          updated.assignQty,
          closeTo(remainingQty, 0.01),
          reason: 'Increment should not exceed remaining quantity',
        );
      }
    });

    test('Property 25: Decrement decreases quantity by 1', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final initialQty = (random.nextDouble() * 20) + 2; // Ensure > 1
        var state = ModalState(assignQty: initialQty);

        final updated = decrementQuantity(state);

        expect(
          updated.assignQty,
          closeTo(initialQty - 1, 0.01),
          reason: 'Decrement should decrease quantity by 1',
        );
      }
    });

    test('Property 25: Decrement does not go below 0.5', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        var state = ModalState(assignQty: 0.5);

        final updated = decrementQuantity(state);

        expect(
          updated.assignQty,
          closeTo(0.5, 0.01),
          reason: 'Decrement should not go below 0.5',
        );
      }
    });

    test('Property 25: Multiple increments accumulate correctly', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 10;
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        var state = ModalState(assignQty: 1.0);
        final incrementCount = random.nextInt(5) + 1;

        for (int j = 0; j < incrementCount; j++) {
          state = incrementQuantity(state, item);
        }

        expect(
          state.assignQty,
          closeTo(1.0 + incrementCount, 0.01),
          reason: 'Multiple increments should accumulate',
        );
      }
    });

    test('Property 25: Multiple decrements accumulate correctly', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final initialQty = (random.nextDouble() * 10) + 5;
        var state = ModalState(assignQty: initialQty);
        final decrementCount = random.nextInt(3) + 1;

        for (int j = 0; j < decrementCount; j++) {
          state = decrementQuantity(state);
        }

        final expectedQty = (initialQty - decrementCount).clamp(0.5, double.infinity);

        expect(
          state.assignQty,
          closeTo(expectedQty, 0.01),
          reason: 'Multiple decrements should accumulate',
        );
      }
    });

    /// Property 26: Avatar toggle in modal
    /// For any member, toggling should add/remove them from selection
    test('Property 26: Toggling adds member if not selected', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        var state = ModalState(assignQty: 1.0);
        final memberId = 'member_${random.nextInt(100)}';

        expect(state.selectedMemberIds.contains(memberId), false);

        final updated = toggleMember(state, memberId);

        expect(
          updated.selectedMemberIds.contains(memberId),
          true,
          reason: 'Toggle should add member if not selected',
        );
      }
    });

    test('Property 26: Toggling removes member if already selected', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberId = 'member_${random.nextInt(100)}';
        var state = ModalState(
          assignQty: 1.0,
          selectedMemberIds: {memberId},
        );

        expect(state.selectedMemberIds.contains(memberId), true);

        final updated = toggleMember(state, memberId);

        expect(
          updated.selectedMemberIds.contains(memberId),
          false,
          reason: 'Toggle should remove member if already selected',
        );
      }
    });

    test('Property 26: Toggling multiple members maintains correct state', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        var state = ModalState(assignQty: 1.0);
        final memberCount = random.nextInt(5) + 2;

        // Add multiple members
        for (int j = 0; j < memberCount; j++) {
          state = toggleMember(state, 'member_$j');
        }

        expect(
          state.selectedMemberIds.length,
          memberCount,
          reason: 'All members should be selected',
        );

        // Remove one member
        final memberToRemove = 'member_${random.nextInt(memberCount)}';
        state = toggleMember(state, memberToRemove);

        expect(
          state.selectedMemberIds.contains(memberToRemove),
          false,
          reason: 'Removed member should not be in selection',
        );

        expect(
          state.selectedMemberIds.length,
          memberCount - 1,
          reason: 'Selection count should decrease by 1',
        );
      }
    });

    test('Property 26: Toggle is idempotent - toggling twice returns to original', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        var state = ModalState(assignQty: 1.0);
        final memberId = 'member_${random.nextInt(100)}';

        final originalCount = state.selectedMemberIds.length;

        // Toggle on then off
        state = toggleMember(state, memberId);
        state = toggleMember(state, memberId);

        expect(
          state.selectedMemberIds.length,
          originalCount,
          reason: 'Double toggle should return to original state',
        );

        expect(
          state.selectedMemberIds.contains(memberId),
          false,
          reason: 'Member should not be selected after double toggle',
        );
      }
    });

    test('Property 26: Toggle preserves other selected members', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final existingMembers = {'member_1', 'member_2', 'member_3'};
        var state = ModalState(
          assignQty: 1.0,
          selectedMemberIds: Set<String>.from(existingMembers),
        );

        final newMember = 'member_4';
        state = toggleMember(state, newMember);

        expect(
          state.selectedMemberIds.containsAll(existingMembers),
          true,
          reason: 'Existing members should remain selected',
        );

        expect(
          state.selectedMemberIds.contains(newMember),
          true,
          reason: 'New member should be added',
        );
      }
    });

    /// Property 27: Assignment button text reflects selection
    /// For any selection state, button text should accurately describe the action
    test('Property 27: Button text shows "Select members" when none selected', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 20) + 1;
        final state = ModalState(assignQty: qty);

        final buttonText = getActionButtonText(state);

        expect(
          buttonText,
          'Select members to assign',
          reason: 'Button should prompt to select members when none selected',
        );
      }
    });

    test('Property 27: Button text shows correct quantity and member count', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 1;

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final state = ModalState(
          assignQty: qty,
          selectedMemberIds: selectedMembers,
        );

        final buttonText = getActionButtonText(state);

        // Check that button text contains the quantity
        final qtyText = qty.toStringAsFixed(
          qty.truncateToDouble() == qty ? 0 : 1,
        );
        expect(
          buttonText.contains(qtyText),
          true,
          reason: 'Button text should contain quantity',
        );

        // Check that button text contains the member count
        expect(
          buttonText.contains(memberCount.toString()),
          true,
          reason: 'Button text should contain member count',
        );
      }
    });

    test('Property 27: Button text uses singular "person" for one member', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 20) + 1;
        final state = ModalState(
          assignQty: qty,
          selectedMemberIds: {'member_1'},
        );

        final buttonText = getActionButtonText(state);

        expect(
          buttonText.contains('person'),
          true,
          reason: 'Button should use singular "person" for one member',
        );

        expect(
          buttonText.contains('people'),
          false,
          reason: 'Button should not use "people" for one member',
        );
      }
    });

    test('Property 27: Button text uses plural "people" for multiple members', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 2; // 2-6 members

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final state = ModalState(
          assignQty: qty,
          selectedMemberIds: selectedMembers,
        );

        final buttonText = getActionButtonText(state);

        expect(
          buttonText.contains('people'),
          true,
          reason: 'Button should use plural "people" for multiple members',
        );

        expect(
          buttonText.contains('person'),
          false,
          reason: 'Button should not use singular "person" for multiple members',
        );
      }
    });

    test('Property 27: Button text updates when selection changes', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 20) + 1;
        var state = ModalState(assignQty: qty);

        // Initially no selection
        var buttonText = getActionButtonText(state);
        expect(buttonText, 'Select members to assign');

        // Add one member
        state = toggleMember(state, 'member_1');
        buttonText = getActionButtonText(state);
        expect(buttonText.contains('1 person'), true);

        // Add another member
        state = toggleMember(state, 'member_2');
        buttonText = getActionButtonText(state);
        expect(buttonText.contains('2 people'), true);

        // Remove one member
        state = toggleMember(state, 'member_1');
        buttonText = getActionButtonText(state);
        expect(buttonText.contains('1 person'), true);
      }
    });

    test('Property 27: Button text formats integer quantities without decimals', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextInt(20) + 1).toDouble(); // Integer quantity
        final state = ModalState(
          assignQty: qty,
          selectedMemberIds: {'member_1'},
        );

        final buttonText = getActionButtonText(state);

        // Should not contain decimal point for integer quantities
        final qtyText = qty.toInt().toString();
        expect(
          buttonText.contains('$qtyText '),
          true,
          reason: 'Integer quantities should not have decimal point',
        );

        expect(
          buttonText.contains('.'),
          false,
          reason: 'Integer quantities should not contain decimal point',
        );
      }
    });

    test('Property 27: Button text formats fractional quantities with decimals', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final qty = (random.nextDouble() * 10) + 0.5; // Fractional quantity
        final state = ModalState(
          assignQty: qty,
          selectedMemberIds: {'member_1'},
        );

        final buttonText = getActionButtonText(state);

        // Should contain decimal point for fractional quantities
        expect(
          buttonText.contains('.'),
          true,
          reason: 'Fractional quantities should contain decimal point',
        );
      }
    });

    /// Integration test: Complete assignment flow
    test('Integration: Complete assignment flow maintains correctness', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Initialize modal state with remaining quantity
        var state = ModalState(assignQty: item.getRemainingCount());

        // Select some members
        final memberCount = random.nextInt(3) + 1;
        for (int j = 0; j < memberCount; j++) {
          state = toggleMember(state, 'member_$j');
        }

        // Adjust quantity
        final adjustments = random.nextInt(3);
        for (int j = 0; j < adjustments; j++) {
          if (random.nextBool()) {
            state = incrementQuantity(state, item);
          } else {
            state = decrementQuantity(state);
          }
        }

        // Create assignment
        final newAssignments = createAssignment(item, state);

        // Verify assignment correctness
        final sharePerPerson = state.assignQty / state.selectedMemberIds.length;
        for (final memberId in state.selectedMemberIds) {
          expect(
            newAssignments[memberId],
            closeTo(sharePerPerson, 0.01),
            reason: 'Each member should get equal share',
          );
        }

        // Verify total assigned
        final totalAssigned = newAssignments.values.fold(0.0, (sum, qty) => sum + qty);
        expect(
          totalAssigned,
          closeTo(state.assignQty, 0.01),
          reason: 'Total assigned should equal selected quantity',
        );
      }
    });

    test('Integration: Multiple assignments accumulate correctly', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 10;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // First assignment
        var state1 = ModalState(assignQty: 2.0, selectedMemberIds: {'member_1'});
        var assignments = createAssignment(item, state1);
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        expect(assignments['member_1'], closeTo(2.0, 0.01));

        // Second assignment
        var state2 = ModalState(assignQty: 3.0, selectedMemberIds: {'member_1', 'member_2'});
        assignments = createAssignment(item, state2);
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        // member_1 should have 2.0 + 1.5 = 3.5
        expect(assignments['member_1'], closeTo(3.5, 0.01));
        // member_2 should have 1.5
        expect(assignments['member_2'], closeTo(1.5, 0.01));

        // Verify remaining
        final remaining = item.getRemainingCount();
        expect(remaining, closeTo(totalQty - 5.0, 0.01));
      }
    });
  });
}
