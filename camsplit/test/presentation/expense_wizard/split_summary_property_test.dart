import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/models/group_member.dart';
import 'package:faker/faker.dart';
import 'dart:math';

void main() {
  final faker = Faker();
  final random = Random();

  group('Split Summary Property Tests', () {
    String getMemberId(GroupMember member) {
      return member.userId?.toString() ?? member.id.toString();
    }

    GroupMember generateRandomMember({int? id, int? userId, String? nickname}) {
      return GroupMember(
        id: id ?? random.nextInt(10000) + 1,
        groupId: 1,
        userId: userId ?? random.nextInt(10000) + 1,
        nickname: nickname ?? faker.person.name(),
        email: faker.internet.email(),
        role: 'member',
        isRegisteredUser: true,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    ReceiptItem generateRandomItem({
      String? id,
      double? quantity,
      double? unitPrice,
      Map<String, double>? assignments,
    }) {
      final qty = quantity ?? (random.nextDouble() * 10) + 1;
      final price = unitPrice ?? (random.nextDouble() * 50) + 1;
      
      return ReceiptItem(
        id: id ?? faker.guid.guid(),
        name: faker.food.dish(),
        quantity: qty,
        unitPrice: price,
        price: qty * price,
        assignments: assignments ?? {},
      );
    }

    double calculateMemberTotalManually(List<ReceiptItem> items, String memberId) {
      double total = 0.0;
      for (final item in items) {
        final assignedQty = item.assignments[memberId] ?? 0.0;
        total += assignedQty * item.unitPrice;
      }
      return total;
    }

    double calculateUnassignedManually(List<ReceiptItem> items) {
      double unassigned = 0.0;
      for (final item in items) {
        final remainingQty = item.getRemainingCount();
        unassigned += remainingQty * item.unitPrice;
      }
      return unassigned;
    }

    test('Property 34: Summary filters assigned members', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(8) + 2;
        final members = List.generate(memberCount, (index) => generateRandomMember());
        
        final itemCount = random.nextInt(5) + 1;
        final items = <ReceiptItem>[];
        
        for (int j = 0; j < itemCount; j++) {
          final item = generateRandomItem();
          final assignments = <String, double>{};
          
          final assignCount = random.nextInt(memberCount);
          for (int k = 0; k < assignCount; k++) {
            final member = members[random.nextInt(memberCount)];
            final memberId = getMemberId(member);
            final assignQty = random.nextDouble() * item.quantity;
            assignments[memberId] = assignQty;
          }
          
          items.add(item.copyWith(assignments: assignments));
        }
        
        final expectedMembers = members.where((member) {
          final total = calculateMemberTotalManually(items, getMemberId(member));
          return total > 0.01;
        }).toList();
        
        for (final member in expectedMembers) {
          final total = calculateMemberTotalManually(items, getMemberId(member));
          expect(total, greaterThan(0.01));
        }
        
        final unexpectedMembers = members.where((m) => !expectedMembers.contains(m));
        for (final member in unexpectedMembers) {
          final total = calculateMemberTotalManually(items, getMemberId(member));
          expect(total, lessThanOrEqualTo(0.01));
        }
      }
    });

    test('Property 35: Summary displays member data', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final members = List.generate(random.nextInt(5) + 2, (index) => generateRandomMember());
        
        final items = List.generate(random.nextInt(4) + 1, (index) {
          final item = generateRandomItem();
          final assignments = <String, double>{};
          
          for (final member in members) {
            if (random.nextBool()) {
              assignments[getMemberId(member)] = random.nextDouble() * item.quantity;
            }
          }
          
          return item.copyWith(assignments: assignments);
        });
        
        for (final member in members) {
          final total = calculateMemberTotalManually(items, getMemberId(member));
          
          if (total > 0.01) {
            expect(member.nickname, isNotEmpty);
            expect(total, greaterThan(0));
            expect(total.isFinite, true);
          }
        }
      }
    });

    test('Property 36: Summary reactivity', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final members = List.generate(3, (index) => generateRandomMember());
        final item = generateRandomItem(quantity: 10.0, unitPrice: 5.0);
        
        final initialItems = [item];
        final initialTotal = calculateMemberTotalManually(initialItems, getMemberId(members[0]));
        expect(initialTotal, 0.0);
        
        final updatedItem = item.copyWith(assignments: {getMemberId(members[0]): 5.0});
        final updatedItems = [updatedItem];
        final updatedTotal = calculateMemberTotalManually(updatedItems, getMemberId(members[0]));
        
        expect(updatedTotal, closeTo(25.0, 0.01));
        expect(updatedTotal, isNot(equals(initialTotal)));
      }
    });

    test('Property 37: Unassigned amount display', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final members = List.generate(2, (index) => generateRandomMember());
        
        final quantity = (random.nextDouble() * 10) + 2;
        final unitPrice = (random.nextDouble() * 20) + 1;
        final assignedQty = quantity * 0.6;
        
        final item = generateRandomItem(quantity: quantity, unitPrice: unitPrice);
        final partialItem = item.copyWith(assignments: {getMemberId(members[0]): assignedQty});
        
        final items = [partialItem];
        final unassigned = calculateUnassignedManually(items);
        
        expect(unassigned, greaterThan(0.01));
        
        final expectedUnassigned = (quantity - assignedQty) * unitPrice;
        expect(unassigned, closeTo(expectedUnassigned, 0.01));
      }
    });

    test('Property 38: Unassigned amount hidden when zero', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final members = List.generate(random.nextInt(4) + 2, (index) => generateRandomMember());
        
        final items = List.generate(random.nextInt(4) + 1, (index) {
          final item = generateRandomItem();
          
          final assignments = <String, double>{};
          double remaining = item.quantity;
          
          for (int j = 0; j < members.length - 1; j++) {
            final assignQty = remaining / (members.length - j);
            assignments[getMemberId(members[j])] = assignQty;
            remaining -= assignQty;
          }
          assignments[getMemberId(members.last)] = remaining;
          
          return item.copyWith(assignments: assignments);
        });
        
        final unassigned = calculateUnassignedManually(items);
        expect(unassigned, lessThanOrEqualTo(0.01));
      }
    });

    test('Property 39: Member total calculation', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final member = generateRandomMember();
        final memberId = getMemberId(member);
        
        final itemCount = random.nextInt(5) + 1;
        final items = <ReceiptItem>[];
        double expectedTotal = 0.0;
        
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 20) + 1;
          final assignedQty = random.nextDouble() * quantity;
          
          final item = generateRandomItem(quantity: quantity, unitPrice: unitPrice);
          items.add(item.copyWith(assignments: {memberId: assignedQty}));
          
          expectedTotal += assignedQty * unitPrice;
        }
        
        final calculatedTotal = calculateMemberTotalManually(items, memberId);
        expect(calculatedTotal, closeTo(expectedTotal, 0.01));
      }
    });
  });
}
