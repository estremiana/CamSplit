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
  final List<String> _categories = [
    'Food & Dining',
    'Transport',
    'Accommodation',
    'Entertainment',
    'Groceries',
    'Other',
  ];

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
            widget.onDataChanged(widget.data.copyWith(groupId: _selectedGroup!.id.toString()));
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
      widget.onDataChanged(widget.data.copyWith(payerId: payer.id.toString()));
    } catch (e) {
      debugPrint('Error setting default payer: $e');
      if (_groupMembers.isNotEmpty) {
        setState(() {
          _selectedPayer = _groupMembers.first;
        });
        widget.onDataChanged(widget.data.copyWith(payerId: _groupMembers.first.id.toString()));
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
      widget.onDataChanged(
        widget.data.copyWith(date: DateFormat('yyyy-MM-dd').format(picked)),
      );
    }
  }

  void _selectGroup(Group group) {
    setState(() {
      _selectedGroup = group;
    });
    widget.onDataChanged(widget.data.copyWith(groupId: group.id.toString()));
    _loadGroupMembers(group.id);
  }

  void _selectPayer(GroupMember member) {
    setState(() {
      _selectedPayer = member;
    });
    widget.onDataChanged(widget.data.copyWith(payerId: member.id.toString()));
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    // Title
                    Text(
                      'The Details',
                      style: TextStyle(
                        fontSize: 28.sp,
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
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
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
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
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
                  Icons.people,
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
                          fontSize: 12.sp,
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GroupMember>(
          value: _selectedPayer,
          isExpanded: true,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
          items: _groupMembers.map((member) {
            return DropdownMenuItem<GroupMember>(
              value: member,
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryLight,
                      size: 4.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    member.nickname,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
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
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CATEGORY'),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: TextEditingController(text: widget.data.category),
            onChanged: (value) {
              widget.onDataChanged(widget.data.copyWith(category: value));
            },
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'General',
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.local_offer,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
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
                        Icons.people,
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
