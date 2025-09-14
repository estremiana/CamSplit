import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './member_avatar_widget.dart';

class MemberSearchWidget extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final Function(String) onMemberSelected;
  final String hintText;

  const MemberSearchWidget({
    super.key,
    required this.members,
    required this.onMemberSelected,
    this.hintText = 'Search members...',
  });

  @override
  State<MemberSearchWidget> createState() => _MemberSearchWidgetState();
}

class _MemberSearchWidgetState extends State<MemberSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.members;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showDropdown = _focusNode.hasFocus && _filteredMembers.isNotEmpty;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = widget.members;
      } else {
        _filteredMembers = widget.members
            .where((member) => member['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
      _showDropdown = _focusNode.hasFocus && _filteredMembers.isNotEmpty;
    });
  }

  void _onMemberTapped(Map<String, dynamic> member) {
    widget.onMemberSelected(member['id'].toString());
    _searchController.clear();
    _filteredMembers = widget.members;
    _focusNode.unfocus();
    setState(() {
      _showDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppTheme.lightTheme.colorScheme.secondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),

        // Dropdown results
        if (_showDropdown)
          Container(
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 30.h),
            child: _filteredMembers.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Text(
                      'No members found',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return ListTile(
                        leading: MemberAvatarWidget(
                          member: member,
                          isSelected: false,
                          onTap: () => _onMemberTapped(member),
                          size: 6.0,
                        ),
                        title: Text(
                          member['name'],
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _onMemberTapped(member),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
