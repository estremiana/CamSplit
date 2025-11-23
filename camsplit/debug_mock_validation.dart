import 'lib/models/mock_group_data.dart';

void main() {
  final groups = MockGroupData.getMockGroups();
  
  print('Total groups: ${groups.length}');
  
  for (int i = 0; i < groups.length; i++) {
    final group = groups[i];
    print('\nGroup ${i + 1}: ${group.name}');
    print('  ID: ${group.id}');
    print('  Valid: ${group.isValid()}');
    print('  Valid timestamps: ${group.hasValidTimestamps()}');
    print('  Has current user: ${group.hasCurrentUser}');
    print('  Members: ${group.members.length}');
    
    for (final member in group.members) {
      print('    - ${member.nickname} (isCurrentUser: ${member.isCurrentUser})');
    }
  }
  
  print('\nValidation result: ${MockGroupData.validateMockData()}');
}