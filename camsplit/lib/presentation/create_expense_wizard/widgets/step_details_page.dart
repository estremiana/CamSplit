import 'package:flutter/material.dart';
import '../models/wizard_expense_data.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../services/group_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

/// Second page of the expense wizard for entering expense details
/// Includes group selection, payer selection, date, and category
class StepDetailsPage extends StatefulWidget {
  final WizardExpenseData wizardData;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(WizardExpenseData) onDataChanged;

  const StepDetailsPage({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onBack,
    required this.onDataChanged,
  });

  @override
  State<StepDetailsPage> createState() => _StepDetailsPageState();
}

class _StepDetailsPageState extends State<StepDetailsPage> {
  late TextEditingController _categoryController;
  
  List<Group> _availableGroups = [];
  List<GroupMember> _groupMembers = [];
  bool _isLoadingGroups = true;
  bool _isLoadingMembers = false;
  
  Group? _selectedGroup;
  GroupMember? _selectedPayer;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.wizardData.category);
    _categoryController.addListener(_onCategoryChanged);
    
    // Initialize selected date from wizard data if available
    if (widget.wizardData.date.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.wizardData.date);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
    
    _loadGroups();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _onCategoryChanged() {
    widget.onDataChanged(widget.wizardData.copyWith(category: _categoryController.text));
  }

  /// Load available groups for selection
  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await GroupService.getAllGroupsWithMembers();
      
      setState(() {
        _availableGroups = groups;
        _isLoadingGroups = false;
      });

      // If wizard data has a group ID, restore it
      if (widget.wizardData.groupId.isNotEmpty) {
        final groupId = int.tryParse(widget.wizardData.groupId);
        if (groupId != null) {
          final group = groups.where((g) => g.id == groupId).firstOrNull;
          if (group != null) {
            await _selectGroup(group);
            
            // If wizard data has a payer ID, restore it
            if (widget.wizardData.payerId.isNotEmpty) {
              final payerId = int.tryParse(widget.wizardData.payerId);
              if (payerId != null) {
                final payer = _groupMembers.where((m) => m.userId == payerId).firstOrNull;
                if (payer != null) {
                  _selectPayer(payer);
                }
              }
            }
          }
        }
      } else if (groups.isNotEmpty) {
        // Auto-select first group if no group is selected
        await _selectGroup(groups.first);
      }
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Select a group and load its members
  Future<void> _selectGroup(Group group) async {
    setState(() {
      _selectedGroup = group;
      _isLoadingMembers = true;
      _groupMembers = [];
      _selectedPayer = null;
    });

    try {
      // Load group with members if not already loaded
      Group? groupWithMembers;
      if (group.members.isEmpty) {
        groupWithMembers = await GroupService.getGroupWithMembers(group.id.toString());
      } else {
        groupWithMembers = group;
      }

      if (groupWithMembers != null && groupWithMembers.members.isNotEmpty) {
        setState(() {
          _groupMembers = groupWithMembers!.members;
          _isLoadingMembers = false;
        });

        // Update wizard data with selected group
        widget.onDataChanged(widget.wizardData.copyWith(
          groupId: group.id.toString(),
        ));

        // Auto-select current user as payer
        await _selectCurrentUserAsPayer();
      } else {
        setState(() {
          _isLoadingMembers = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load group members'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load group members: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Auto-select current user as payer
  Future<void> _selectCurrentUserAsPayer() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      final currentUserId = int.tryParse(currentUser.id);
      
      if (currentUserId != null) {
        final currentUserMember = _groupMembers
            .where((member) => member.userId == currentUserId)
            .firstOrNull;
        
        if (currentUserMember != null) {
          _selectPayer(currentUserMember);
        } else if (_groupMembers.isNotEmpty) {
          // Fallback to first member if current user not found
          _selectPayer(_groupMembers.first);
        }
      } else if (_groupMembers.isNotEmpty) {
        // Fallback to first member if current user ID is invalid
        _selectPayer(_groupMembers.first);
      }
    } catch (e) {
      // If we can't get current user, just select first member
      if (_groupMembers.isNotEmpty) {
        _selectPayer(_groupMembers.first);
      }
    }
  }

  /// Select a payer
  void _selectPayer(GroupMember payer) {
    setState(() {
      _selectedPayer = payer;
    });

    // Update wizard data with selected payer
    widget.onDataChanged(widget.wizardData.copyWith(
      payerId: payer.userId?.toString() ?? payer.id.toString(),
    ));
  }

  /// Show group selection dialog
  Future<void> _showGroupSelectionDialog() async {
    final selectedGroup = await showDialog<Group>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingGroups
                ? const Center(child: CircularProgressIndicator())
                : _availableGroups.isEmpty
                    ? const Center(child: Text('No groups available'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableGroups.length,
                        itemBuilder: (context, index) {
                          final group = _availableGroups[index];
                          return ListTile(
                            title: Text(group.name),
                            subtitle: Text('${group.memberCount} members'),
                            selected: _selectedGroup?.id == group.id,
                            onTap: () => Navigator.of(context).pop(group),
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedGroup != null) {
      await _selectGroup(selectedGroup);
    }
  }

  /// Show payer selection dialog
  Future<void> _showPayerSelectionDialog() async {
    if (_groupMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group first')),
      );
      return;
    }

    final selectedPayer = await showDialog<GroupMember>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Who Paid?'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _groupMembers.length,
              itemBuilder: (context, index) {
                final member = _groupMembers[index];
                return ListTile(
                  title: Text(member.displayName),
                  selected: _selectedPayer?.id == member.id,
                  onTap: () => Navigator.of(context).pop(member),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedPayer != null) {
      _selectPayer(selectedPayer);
    }
  }

  /// Show date picker
  Future<void> _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // Update wizard data with selected date
      widget.onDataChanged(widget.wizardData.copyWith(
        date: pickedDate.toIso8601String(),
      ));
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isDetailsValid() {
    return widget.wizardData.isDetailsValid();
  }

  void _handleNext() {
    if (_isDetailsValid()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDetailsValid = _isDetailsValid();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator with animation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page 2 of 3',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // Page title
                    Text(
                      'Expense Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Group selector
                    _buildSelectorCard(
                      icon: Icons.group_outlined,
                      label: 'Group',
                      value: _selectedGroup?.name ?? 'Select group',
                      isLoading: _isLoadingGroups,
                      onTap: _showGroupSelectionDialog,
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),

                    // Payer selector
                    _buildSelectorCard(
                      icon: Icons.person_outline,
                      label: 'Who Paid?',
                      value: _selectedPayer?.displayName ?? 'Select payer',
                      isLoading: _isLoadingMembers,
                      onTap: _showPayerSelectionDialog,
                      isRequired: true,
                      enabled: _selectedGroup != null,
                    ),

                    const SizedBox(height: 16),

                    // Date picker
                    _buildSelectorCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: _formatDate(_selectedDate),
                      onTap: _showDatePicker,
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),

                    // Category input
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        hintText: 'e.g., Food, Transport, Entertainment',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const Spacer(),
                  // Next button
                  ElevatedButton(
                    onPressed: isDetailsValid ? _handleNext : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a selector card widget with visual feedback
  Widget _buildSelectorCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isRequired = false,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isPlaceholder = value.startsWith('Select');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled 
                  ? theme.colorScheme.outline 
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
          children: [
            Icon(
              icon,
              color: enabled 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          value,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isPlaceholder
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                            fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: enabled 
                  ? theme.colorScheme.onSurfaceVariant 
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
