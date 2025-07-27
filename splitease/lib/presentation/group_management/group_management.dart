import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/create_group_modal_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/group_card_widget.dart';

class GroupManagement extends StatefulWidget {
  const GroupManagement({Key? key}) : super(key: key);

  @override
  State<GroupManagement> createState() => _GroupManagementState();
}

class _GroupManagementState extends State<GroupManagement>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _selectedGroupIds = [];
  bool _isMultiSelectMode = false;
  int _currentBottomNavIndex = 1;

  // Mock data for groups
  final List<Map<String, dynamic>> _allGroups = [
    {
      "id": 1,
      "name": "Roommates",
      "description": "Monthly apartment expenses",
      "memberCount": 4,
      "totalBalance": 245.50,
      "currency": "USD",
      "isPositive": true,
      "lastActivity": DateTime.now().subtract(Duration(hours: 2)),
      "members": [
        {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 85.25,
          "isPositive": true
        },
        {
          "id": 2,
          "name": "Sarah Wilson",
          "email": "sarah@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": -42.75,
          "isPositive": false
        },
        {
          "id": 3,
          "name": "Mike Johnson",
          "email": "mike@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 125.00,
          "isPositive": true
        },
        {
          "id": 4,
          "name": "Emma Davis",
          "email": "emma@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 78.00,
          "isPositive": true
        }
      ],
      "recentExpenses": [
        {
          "title": "Grocery Shopping",
          "amount": 156.78,
          "date": DateTime.now().subtract(Duration(hours: 6))
        },
        {
          "title": "Electricity Bill",
          "amount": 89.50,
          "date": DateTime.now().subtract(Duration(days: 1))
        }
      ]
    },
    {
      "id": 2,
      "name": "Weekend Trip",
      "description": "Beach vacation expenses",
      "memberCount": 6,
      "totalBalance": -125.30,
      "currency": "USD",
      "isPositive": false,
      "lastActivity": DateTime.now().subtract(Duration(days: 1)),
      "members": [
        {
          "id": 5,
          "name": "Alex Chen",
          "email": "alex@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": -45.20,
          "isPositive": false
        },
        {
          "id": 6,
          "name": "Lisa Brown",
          "email": "lisa@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 32.50,
          "isPositive": true
        },
        {
          "id": 7,
          "name": "David Lee",
          "email": "david@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": -67.80,
          "isPositive": false
        },
        {
          "id": 8,
          "name": "Rachel Green",
          "email": "rachel@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 89.25,
          "isPositive": true
        },
        {
          "id": 9,
          "name": "Tom Wilson",
          "email": "tom@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": -78.45,
          "isPositive": false
        },
        {
          "id": 10,
          "name": "Amy Taylor",
          "email": "amy@example.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": -55.60,
          "isPositive": false
        }
      ],
      "recentExpenses": [
        {
          "title": "Hotel Booking",
          "amount": 450.00,
          "date": DateTime.now().subtract(Duration(days: 2))
        },
        {
          "title": "Restaurant Dinner",
          "amount": 234.75,
          "date": DateTime.now().subtract(Duration(days: 1))
        }
      ]
    },
    {
      "id": 3,
      "name": "Office Lunch",
      "description": "Weekly team lunch expenses",
      "memberCount": 8,
      "totalBalance": 0.00,
      "currency": "USD",
      "isPositive": true,
      "lastActivity": DateTime.now().subtract(Duration(days: 3)),
      "members": [
        {
          "id": 11,
          "name": "James Miller",
          "email": "james@company.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 0.00,
          "isPositive": true
        },
        {
          "id": 12,
          "name": "Jennifer White",
          "email": "jennifer@company.com",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "balance": 0.00,
          "isPositive": true
        }
      ],
      "recentExpenses": [
        {
          "title": "Pizza Lunch",
          "amount": 89.50,
          "date": DateTime.now().subtract(Duration(days: 3))
        }
      ]
    }
  ];

  List<Map<String, dynamic>> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(_allGroups);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredGroups = _allGroups.where((group) {
        return (group['name'] as String).toLowerCase().contains(_searchQuery) ||
            (group['description'] as String)
                .toLowerCase()
                .contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _filteredGroups = List.from(_allGroups);
      }
    });
  }

  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupModalWidget(
        onGroupCreated: (groupData) {
          setState(() {
            _allGroups.add({
              "id": _allGroups.length + 1,
              "name": groupData['name'],
              "description": groupData['description'],
              "memberCount": 1,
              "totalBalance": 0.00,
              "currency": groupData['currency'],
              "isPositive": true,
              "lastActivity": DateTime.now(),
              "members": [],
              "recentExpenses": []
            });
            _filteredGroups = List.from(_allGroups);
          });
        },
      ),
    );
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedGroupIds.clear();
      }
    });
  }

  void _toggleGroupSelection(int groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  void _handleBatchOperation(String operation) {
    // Handle batch operations like archive, delete, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $operation'),
        content: Text(
            'Are you sure you want to $operation ${_selectedGroupIds.length} group(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform operation
              setState(() {
                _selectedGroupIds.clear();
                _isMultiSelectMode = false;
              });
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                style: AppTheme.lightTheme.textTheme.titleMedium,
              )
            : Text(
                'Groups',
                style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
              ),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              onPressed: () => _handleBatchOperation('archive'),
              icon: CustomIconWidget(
                iconName: 'archive',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: () => _handleBatchOperation('delete'),
              icon: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorLight,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _toggleMultiSelect,
              icon: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ] else ...[
            IconButton(
              onPressed: _toggleSearch,
              icon: CustomIconWidget(
                iconName: _isSearching ? 'close' : 'search',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _toggleMultiSelect,
              icon: CustomIconWidget(
                iconName: 'checklist',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ],
        ],
      ),
      body: _filteredGroups.isEmpty && _searchQuery.isNotEmpty
          ? _buildNoSearchResults()
          : _filteredGroups.isEmpty
              ? EmptyStateWidget(onCreateGroup: _showCreateGroupModal)
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _onRefresh,
                  child: _buildGroupsList(),
                ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _showCreateGroupModal,
              backgroundColor:
                  AppTheme.lightTheme.floatingActionButtonTheme.backgroundColor,
              child: CustomIconWidget(
                iconName: 'add',
                color: AppTheme
                    .lightTheme.floatingActionButtonTheme.foregroundColor,
                size: 24,
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.cardColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryLight,
      elevation: 8.0,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard_outlined',
            color: _currentBottomNavIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'group_outlined',
            color: _currentBottomNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'group',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person_outlined',
            color: _currentBottomNavIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onBottomNavTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/expense-dashboard');
        break;
      case 1:
        // Already on groups screen
        break;
      case 2:
        Navigator.pushNamed(context, '/profile-settings');
        break;
    }
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No groups found',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try searching with different keywords',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        final isSelected = _selectedGroupIds.contains(group['id']);

        return GroupCardWidget(
          group: group,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: isSelected,
          onTap: () {
            if (_isMultiSelectMode) {
              _toggleGroupSelection(group['id']);
            }
          },
          onLongPress: () {
            if (!_isMultiSelectMode) {
              _toggleMultiSelect();
              _toggleGroupSelection(group['id']);
            }
          },
          onViewDetails: () {
            Navigator.pushNamed(
              context,
              AppRoutes.groupDetail,
              arguments: {'groupId': group['id']},
            );
          },
          onEdit: () {
            // Navigate to edit group screen
          },
          onInvite: () {
            // Show invite members modal
          },
          onSettings: () {
            // Navigate to group settings
          },
          onArchive: () {
            // Archive group
          },
          onLeave: () {
            // Leave group
          },
        );
      },
    );
  }
}
