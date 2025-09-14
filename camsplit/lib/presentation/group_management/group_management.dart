import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import './widgets/create_group_modal_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/group_card_widget.dart';

class GroupManagement extends StatefulWidget {
  final bool showBottomNavigation;
  
  const GroupManagement({
    super.key,
    this.showBottomNavigation = true,
  });

  @override
  State<GroupManagement> createState() => _GroupManagementState();
}

class _GroupManagementState extends State<GroupManagement>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Group> _allGroups = [];
  List<Group> _filteredGroups = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isMultiSelectMode = false;
  Set<int> _selectedGroupIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasProcessedArguments = false; // Flag to track if arguments have been processed
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  int _currentBottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _hasProcessedArguments = false; // Reset flag
    _loadGroups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to refresh (e.g., after returning from group detail)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Debug logging
    if (args != null) {
      print('GroupManagement: Received arguments: $args');
    }
    
    if (args?['refresh'] == true && !_hasProcessedArguments) {
      _hasProcessedArguments = true; // Mark as processed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshGroups();
          
          // Show success message if provided and not empty
          if (args?['successMessage'] != null && args!['successMessage'].toString().isNotEmpty) {
            print('GroupManagement: Showing success message: ${args!['successMessage']}');
            _showSuccessSnackBar(args!['successMessage']);
          }
          
          // Reset flag after processing to allow future navigations
          _hasProcessedArguments = false;
        }
      });
    }
    
    // Handle new group creation flow
    if (args?['newGroupCreated'] == true && !_hasProcessedArguments) {
      _hasProcessedArguments = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshGroups();
          _showSuccessSnackBar('Group created successfully! You can now add expenses and invite members.');
          _hasProcessedArguments = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load groups from the backend
  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final groups = await GroupService.getAllGroupsWithMembers();
      if (mounted) {
        setState(() {
          _allGroups = groups;
          _filteredGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load groups: $e');
      }
    }
  }

  /// Refresh groups data
  Future<void> _refreshGroups() async {
    try {
      final groups = await GroupService.getAllGroupsWithMembers(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allGroups = groups;
          _filteredGroups = _searchQuery.isEmpty ? groups : _filterGroups(groups, _searchQuery);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to refresh groups: $e');
      }
    }
  }

  /// Filter groups based on search query
  List<Group> _filterGroups(List<Group> groups, String query) {
    if (query.isEmpty) return groups;
    
    final lowercaseQuery = query.toLowerCase();
    return groups.where((group) {
      return group.name.toLowerCase().contains(lowercaseQuery) ||
             (group.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Handle search query changes
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      _filteredGroups = _filterGroups(_allGroups, query);
    });
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _filteredGroups = _allGroups;
      }
    });
  }

  /// Toggle multi-select mode
  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedGroupIds.clear();
      }
    });
  }

  /// Toggle group selection in multi-select mode
  void _toggleGroupSelection(int groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  /// Show create group modal
  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGroupModalWidget(
        onGroupCreated: (Group newGroup) {
          setState(() {
            _allGroups.add(newGroup);
            _filteredGroups = _searchQuery.isEmpty ? _allGroups : _filterGroups(_allGroups, _searchQuery);
          });
          _showSuccessSnackBar('Group created successfully!');
        },
      ),
    );
  }

  /// Handle refresh
  Future<void> _onRefresh() async {
    await _refreshGroups();
  }

  /// Handle batch operations like archive, delete, etc.
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



  /// Handle group invite
  void _handleGroupInvite(Group group) {
    // Navigate to group detail page with invite focus
    Navigator.pushNamed(
      context, 
      AppRoutes.groupDetail,
      arguments: {'groupId': group.id},
    );
  }

  /// Handle view group details
  void _handleViewDetails(Group group) {
    Navigator.pushNamed(
      context, 
      AppRoutes.groupDetail,
      arguments: {'groupId': group.id},
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                onChanged: _onSearchChanged,
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.primaryColor,
              ),
            )
          : _filteredGroups.isEmpty && _searchQuery.isNotEmpty
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
      bottomNavigationBar: widget.showBottomNavigation ? _buildBottomNavigationBar() : null,
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
        final isSelected = _selectedGroupIds.contains(group.id);

        return GroupCardWidget(
          group: group,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: isSelected,
          onTap: () {
            if (_isMultiSelectMode) {
              _toggleGroupSelection(group.id);
            } else {
              Navigator.pushNamed(
                context,
                AppRoutes.groupDetail,
                arguments: {'groupId': group.id},
              );
            }
          },
          onLongPress: () {
            if (!_isMultiSelectMode) {
              _toggleMultiSelect();
              _toggleGroupSelection(group.id);
            }
          },
        );
      },
    );
  }
}
