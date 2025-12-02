import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/app_export.dart';
import '../../../models/expense_detail_model.dart';
import '../../../models/group_member.dart';
import '../../../presentation/expense_creation_wizard/widgets/split_text_styles.dart';
import '../../../services/api_service.dart';

class ExpenseDetailsCard extends StatefulWidget {
  final ExpenseDetailModel expense;
  final bool isEditMode;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController categoryController;
  final DateTime? selectedDate;
  final int? selectedPayerId;
  final List<GroupMember> groupMembers;
  final Function(DateTime) onDateChanged;
  final Function(int?) onPayerChanged;
  final Function(String) onCategoryChanged;
  final Function(String?) onReceiptImageUrlChanged;
  final Function()? onReceiptRemoved;

  const ExpenseDetailsCard({
    Key? key,
    required this.expense,
    required this.isEditMode,
    required this.titleController,
    required this.amountController,
    required this.categoryController,
    required this.selectedDate,
    required this.selectedPayerId,
    required this.groupMembers,
    required this.onDateChanged,
    required this.onPayerChanged,
    required this.onCategoryChanged,
    required this.onReceiptImageUrlChanged,
    this.onReceiptRemoved,
  }) : super(key: key);

  @override
  State<ExpenseDetailsCard> createState() => _ExpenseDetailsCardState();
}

class _ExpenseDetailsCardState extends State<ExpenseDetailsCard> {
  final ImagePicker _picker = ImagePicker();
  String? _tempReceiptImageUrl;
  File? _tempReceiptImageFile;
  bool _isUploadingReceipt = false;

  @override
  Widget build(BuildContext context) {
    final currentReceiptUrl = _tempReceiptImageUrl ?? widget.expense.receiptImageUrl;
    final hasReceipt = currentReceiptUrl != null && currentReceiptUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Paid By
          _buildDetailRow(
            icon: Icons.person,
            label: 'PAID BY',
            style: SplitTextStyles.labelLarge(AppTheme.textPrimaryLight),
            child: widget.isEditMode
                ? _buildPayerDropdown()
                : Text(
                    _getPayerName(),
                    style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
                  ),
          ),
          
          Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
          
          // Date and Category (side by side)
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'DATE',
                  style: SplitTextStyles.labelLarge(AppTheme.textPrimaryLight),
                  child: widget.isEditMode
                      ? _buildDatePicker(context)
                      : Text(
                          _formatDate(widget.expense.date),
                          style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight), 
                        ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildDetailRow(
                  icon: Icons.tag,
                  label: 'CATEGORY',
                  style: SplitTextStyles.labelLarge(AppTheme.textPrimaryLight),
                  child: widget.isEditMode
                      ? _buildCategoryField()
                      : Text(
                          widget.expense.category,
                          style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight), 
                        ),
                ),
              ),
            ],
          ),
          
          Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
          
          // Receipt Section
          _buildReceiptSection(context, hasReceipt, currentReceiptUrl),
          
          Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
          
          // Group (read-only)
          _buildDetailRow(
            icon: Icons.people,
            label: 'GROUP',
            style: SplitTextStyles.labelLarge(AppTheme.textPrimaryLight),
            child: Text(
              widget.expense.groupName,
              style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget child,
    TextStyle? style,
    Color? backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: backgroundColor,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: style ?? SplitTextStyles.labelSmall(AppTheme.textSecondaryLight),
                ),
                SizedBox(height: 0.5.h),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(BuildContext context, bool hasReceipt, String? receiptUrl) {
    return Column(
      children: [
        // Label Row: Icon + Label on left, content on right
        Container(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt,
                  size: 16,
                  color: AppTheme.primaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'RECEIPT',
                style: SplitTextStyles.labelLarge(AppTheme.textPrimaryLight),
              ),
              Spacer(),
              if (_isUploadingReceipt)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                  ),
                )
              else if (hasReceipt)
                // In read mode, show nothing on the right when receipt exists
                SizedBox.shrink()
              else
                // No receipt - show text or button on the right, filling available space
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: widget.isEditMode
                        ? InkWell(
                            onTap: () => _showImageSourceDialog(context),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryLight.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Add receipt image',
                                style: SplitTextStyles.bodyMedium(AppTheme.primaryLight),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Text(
                            'No receipt attached',
                            style: SplitTextStyles.bodyMedium(AppTheme.textSecondaryLight),
                            textAlign: TextAlign.right,
                          ),
                  ),
                ),
            ],
          ),
        ),
        // Image Row: Below label row, only shown when receipt exists
        if (hasReceipt)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: _buildReceiptPreview(context, receiptUrl!),
          ),
      ],
    );
  }


  Widget _buildReceiptPreview(BuildContext context, String receiptUrl) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Make the entire image tappable
          InkWell(
            onTap: () => _showFullReceipt(context, receiptUrl),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _tempReceiptImageFile != null
                  ? Image.file(
                      _tempReceiptImageFile!,
                      width: double.infinity,
                      height: 150.0, // Fixed height as specified
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150.0,
                          color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        );
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: receiptUrl,
                      width: double.infinity,
                      height: 150.0, // Fixed height as specified
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150.0,
                        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150.0,
                        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          // Edit/Delete buttons in edit mode
          if (widget.isEditMode)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  // Edit button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, size: 18, color: AppTheme.textPrimaryLight),
                      onPressed: _isUploadingReceipt ? null : () => _showImageSourceDialog(context),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Delete button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.white),
                      onPressed: _isUploadingReceipt ? null : _handleRemoveReceipt,
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          // Loading overlay during upload
          if (_isUploadingReceipt)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        final imageFile = File(image.path);
        setState(() {
          _tempReceiptImageFile = imageFile;
          _isUploadingReceipt = true;
        });

        // Upload image to server
        await _uploadReceiptImage(imageFile);
      }
    } catch (e) {
      setState(() {
        _isUploadingReceipt = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadReceiptImage(File imageFile) async {
    try {
      final apiService = ApiService.instance;
      final response = await apiService.uploadImage(imageFile);

      if (response['success'] == true && response['data'] != null) {
        final imageUrl = response['data']['image_url'];
        if (imageUrl != null) {
          setState(() {
            _tempReceiptImageUrl = imageUrl;
            _isUploadingReceipt = false;
          });
          widget.onReceiptImageUrlChanged(imageUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Receipt uploaded successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('No image URL in response');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to upload receipt');
      }
    } catch (e) {
      setState(() {
        _isUploadingReceipt = false;
        _tempReceiptImageFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleRemoveReceipt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Receipt?'),
        content: Text('Are you sure you want to remove this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeReceipt();
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeReceipt() async {
    try {
      // Try to get receipt image ID from expense and delete from server
      try {
        final receiptImages = await ApiService.instance.getReceiptImages(widget.expense.id.toString());
        
        if (receiptImages['success'] == true && receiptImages['data'] != null) {
          final images = receiptImages['data'] as List;
          if (images.isNotEmpty) {
            // Delete the first receipt image (assuming one receipt per expense)
            final receiptImageId = images[0]['id'].toString();
            await ApiService.instance.deleteReceiptImage(receiptImageId);
          }
        }
      } catch (e) {
        // If deletion from server fails, continue anyway - we'll clear the URL in the expense
        debugPrint('Note: Could not delete receipt from server: $e');
      }

      setState(() {
        _tempReceiptImageUrl = null;
        _tempReceiptImageFile = null;
      });
      
      widget.onReceiptImageUrlChanged(null);
      if (widget.onReceiptRemoved != null) {
        widget.onReceiptRemoved!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullReceipt(BuildContext context, String receiptUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: receiptUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 64),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerDropdown() {
    return DropdownButton<int>(
      value: widget.selectedPayerId ?? widget.expense.payerId,
      isExpanded: true,
      underline: SizedBox(),
      items: widget.groupMembers.map((member) {
        return DropdownMenuItem<int>(
          value: member.id,
          child: Text(
            member.nickname,
            style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
          ),
        );
      }).toList(),
      onChanged: (value) => widget.onPayerChanged(value),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.selectedDate ?? widget.expense.date,
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now().add(Duration(days: 30)),
        );
        if (picked != null) {
          widget.onDateChanged(picked);
        }
      },
      child: Text(
        _formatDate(widget.selectedDate ?? widget.expense.date),
        style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
      ),
    );
  }

  Widget _buildCategoryField() {
    return TextField(
      controller: widget.categoryController,
      style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String _getPayerName() {
    if (widget.selectedPayerId != null) {
      final member = widget.groupMembers.firstWhere(
        (m) => m.id == widget.selectedPayerId,
        orElse: () => widget.groupMembers.first,
      );
      return member.nickname;
    }
    return widget.expense.payerName;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

