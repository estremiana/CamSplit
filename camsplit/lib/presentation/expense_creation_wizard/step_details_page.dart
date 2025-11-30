import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import 'models/expense_wizard_data.dart';

class StepDetailsPage extends StatefulWidget {
  final ExpenseWizardData data;
  final Function(ExpenseWizardData) onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepDetailsPage({
    Key? key,
    required this.data,
    required this.onDataChanged,
    required this.onBack,
    required this.onNext,
  }) : super(key: key);

  @override
  State<StepDetailsPage> createState() => _StepDetailsPageState();
}

class _StepDetailsPageState extends State<StepDetailsPage> {
  List<Group> _groups = [];
  List<GroupMember> _groupMembers = [];
  bool _isLoadingGroups = false;
  bool _isLoadingMembers = false;
  Group? _selectedGroup;
  GroupMember? _selectedPayer;
  DateTime _selectedDate = DateTime.now();
  final List<String> _defaultCategories = [
    'Food & Dining',
    'Transport',
    'Accommodation',
    'Entertainment',
    'Groceries',
    'Other',
  ];

  List<String> get _availableCategories {
    final categories = List<String>.from(_defaultCategories);
    // If OCR provided a category that's not in the default list, add it
    if (widget.data.category != null && 
        widget.data.category!.isNotEmpty && 
        !_defaultCategories.contains(widget.data.category)) {
      categories.insert(0, widget.data.category!); // Add OCR category at the beginning
    }
    return categories;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.tryParse(widget.data.date) ?? DateTime.now();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await GroupService.getAllGroups();
      
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
          
          // Pre-select group if groupId provided
          if (widget.data.groupId != null && widget.data.groupId!.isNotEmpty) {
            final groupId = int.tryParse(widget.data.groupId!);
            if (groupId != null) {
              _selectedGroup = groups.firstWhere(
                (g) => g.id == groupId,
                orElse: () => groups.isNotEmpty ? groups.first : throw Exception('No groups'),
              );
            } else {
              _selectedGroup = groups.isNotEmpty ? groups.first : null;
            }
          } else {
            _selectedGroup = groups.isNotEmpty ? groups.first : null;
          }
          
          if (_selectedGroup != null) {
            final newData = widget.data.copyWith(groupId: _selectedGroup!.id.toString());
            debugPrint('🔍 [STEP2] Setting groupId - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
            widget.onDataChanged(newData);
            _loadGroupMembers(_selectedGroup!.id);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGroupMembers(int groupId) async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final group = await GroupService.getGroupWithMembers(groupId.toString());
      
      if (mounted && group != null) {
        setState(() {
          _groupMembers = group.members;
          _isLoadingMembers = false;
          
          // Set default payer to current user if not already set
          if (widget.data.payerId == null || widget.data.payerId!.isEmpty) {
            _setDefaultPayer();
          } else {
            _selectedPayer = _groupMembers.firstWhere(
              (m) => m.id.toString() == widget.data.payerId,
              orElse: () => _groupMembers.isNotEmpty ? _groupMembers.first : throw Exception('No members'),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _setDefaultPayer() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      final payer = _groupMembers.firstWhere(
        (m) => m.userId == currentUser.id,
        orElse: () => _groupMembers.isNotEmpty ? _groupMembers.first : throw Exception('No members'),
      );
      setState(() {
        _selectedPayer = payer;
      });
      final newData = widget.data.copyWith(payerId: payer.id.toString());
      debugPrint('🔍 [STEP2] Setting payerId - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
      widget.onDataChanged(newData);
    } catch (e) {
      debugPrint('Error setting default payer: $e');
      if (_groupMembers.isNotEmpty) {
        setState(() {
          _selectedPayer = _groupMembers.first;
        });
        final newData = widget.data.copyWith(payerId: _groupMembers.first.id.toString());
        debugPrint('🔍 [STEP2] Setting default payerId - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
        widget.onDataChanged(newData);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final newData = widget.data.copyWith(date: DateFormat('yyyy-MM-dd').format(picked));
      debugPrint('🔍 [STEP2] Setting date - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
      widget.onDataChanged(newData);
    }
  }

  void _selectGroup(Group group) {
    setState(() {
      _selectedGroup = group;
    });
    final newData = widget.data.copyWith(groupId: group.id.toString());
    debugPrint('🔍 [STEP2] Selecting group - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
    widget.onDataChanged(newData);
    _loadGroupMembers(group.id);
  }

  void _selectPayer(GroupMember member) {
    setState(() {
      _selectedPayer = member;
    });
    final newData = widget.data.copyWith(payerId: member.id.toString());
    debugPrint('🔍 [STEP2] Selecting payer - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
    widget.onDataChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: Text(
                      'Back',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '2 of 3',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNext,
                    child: Text(
                      'Next',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    SizedBox(height: 2.h),
                    // Title
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Group Selector
                    _buildSectionLabel('GROUP'),
                    SizedBox(height: 1.h),
                    _buildGroupSelector(),
                    SizedBox(height: 3.h),
                    // Payer Selector
                    _buildSectionLabel('WHO PAID?'),
                    SizedBox(height: 1.h),
                    _buildPayerSelector(),
                    SizedBox(height: 3.h),
                    // Date and Category Row
                    Row(
                      children: [
                        Expanded(child: _buildDateSelector()),
                        SizedBox(width: 3.w),
                        Expanded(child: _buildCategorySelector()),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 1.w),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppTheme.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    if (_isLoadingGroups) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showGroupPicker(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedGroup?.name ?? 'Select Group',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (_selectedGroup != null)
                      Text(
                        '${_selectedGroup!.memberCount} Members',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryLight,
                size: 6.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayerSelector() {
    if (_isLoadingMembers) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<GroupMember>(
              value: _selectedPayer,
              isExpanded: true,
              padding: EdgeInsets.only(left: 12.w, right: 4.w),
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
              items: _groupMembers.map((member) {
                return DropdownMenuItem<GroupMember>(
                  value: member,
                  child: Text(
                    member.nickname,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (GroupMember? member) {
                if (member != null) {
                  _selectPayer(member);
                }
              },
            ),
          ),
          Positioned(
            left: 4.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.person_outline,
                color: AppTheme.primaryLight,
                size: 5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('DATE'),
        SizedBox(height: 1.h),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.5.h),
              height: 8.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 4.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = _availableCategories;
    final selectedCategory = widget.data.category?.isNotEmpty == true 
        ? widget.data.category 
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CATEGORY'),
        SizedBox(height: 1.h),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.5.h),
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      hint: Text(
                        'General',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryLight.withOpacity(0.5),
                        ),
                      ),
                      icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          final newData = widget.data.copyWith(category: value);
                          debugPrint('🔍 [STEP2] Setting category - items count before: ${widget.data.items.length}, after: ${newData.items.length}');
                          widget.onDataChanged(newData);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Group',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ListTile(
                    leading: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${group.memberCount} Members'),
                    trailing: _selectedGroup?.id == group.id
                        ? Icon(Icons.check, color: AppTheme.primaryLight)
                        : null,
                    onTap: () {
                      _selectGroup(group);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
