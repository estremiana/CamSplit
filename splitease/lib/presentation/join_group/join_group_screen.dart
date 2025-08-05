import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/invite.dart';
import '../../utils/loading_overlay.dart';
import '../../utils/snackbar_utils.dart';

class JoinGroupScreen extends StatefulWidget {
  final String inviteCode;

  const JoinGroupScreen({
    Key? key,
    required this.inviteCode,
  }) : super(key: key);

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final ApiService _apiService = ApiService.instance;
  final LoadingOverlay _loadingOverlay = LoadingOverlay();
  
  InviteDetails? _inviteDetails;
  List<AvailableMember> _availableMembers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInviteDetails();
  }

  Future<void> _loadInviteDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.getInviteDetails(widget.inviteCode);
      
      if (response['success']) {
        final inviteDetails = InviteDetails.fromJson(response['data']);
        final membersResponse = await _apiService.getAvailableMembers(widget.inviteCode);
        
        List<AvailableMember> members = [];
        if (membersResponse['success']) {
          members = (membersResponse['data']['members'] as List)
              .map((member) => AvailableMember.fromJson(member))
              .toList();
        }

        setState(() {
          _inviteDetails = inviteDetails;
          _availableMembers = members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load invite details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinByClaimingMember(AvailableMember member) async {
    try {
      _loadingOverlay.show(context, 'Joining group...');
      
      final response = await _apiService.joinByClaimingMember(
        widget.inviteCode, 
        member.id
      );
      
      _loadingOverlay.hide();
      
      if (response['success']) {
        SnackBarUtils.showSuccess(context, 'Successfully joined group!');
        Navigator.of(context).pop(true); // Return success
      } else {
        SnackBarUtils.showError(context, response['message'] ?? 'Failed to join group');
      }
    } catch (e) {
      _loadingOverlay.hide();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<void> _joinByCreatingMember() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateMemberScreen(inviteCode: widget.inviteCode),
      ),
    );
    
    if (result == true) {
      Navigator.of(context).pop(true); // Return success
    }
  }

  void _copyInviteLink() {
    if (_inviteDetails?.invite.inviteUrl != null) {
      Clipboard.setData(ClipboardData(text: _inviteDetails!.invite.inviteUrl!));
      SnackBarUtils.showSuccess(context, 'Invite link copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInviteDetails,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_inviteDetails == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupInfo(),
          const SizedBox(height: 24),
          _buildInviteInfo(),
          const SizedBox(height: 32),
          _buildJoinOptions(),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inviteDetails!.groupName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            if (_inviteDetails!.groupDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                _inviteDetails!.groupDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInviteInfo() {
    final invite = _inviteDetails!.invite;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invite Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Status', invite.statusText),
            _buildInfoRow('Uses', '${invite.currentUses}/${invite.maxUses}'),
            if (invite.expiresAt != null)
              _buildInfoRow('Expires', _formatDate(invite.expiresAt!)),
            if (invite.inviteUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invite.inviteUrl!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copyInviteLink,
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy invite link',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join Options',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Option 1: Claim existing member
        if (_availableMembers.isNotEmpty) ...[
          Card(
            child: ListTile(
              leading: Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Claim Existing Member'),
              subtitle: Text('Join as one of ${_availableMembers.length} existing members'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showMemberSelectionDialog(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Option 2: Create new member
        Card(
          child: ListTile(
            leading: Icon(
              Icons.person_add_alt_1,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Create New Member'),
            subtitle: const Text('Join with a new member profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _joinByCreatingMember,
          ),
        ),
      ],
    );
  }

  void _showMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableMembers.length,
            itemBuilder: (context, index) {
              final member = _availableMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.nickname[0].toUpperCase()),
                ),
                title: Text(member.nickname),
                subtitle: member.email != null ? Text(member.email!) : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _joinByClaimingMember(member);
                },
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CreateMemberScreen extends StatefulWidget {
  final String inviteCode;

  const CreateMemberScreen({
    Key? key,
    required this.inviteCode,
  }) : super(key: key);

  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  final LoadingOverlay _loadingOverlay = LoadingOverlay();

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _loadingOverlay.show(context, 'Creating member...');
      
      final response = await _apiService.joinByCreatingMember(
        widget.inviteCode,
        _nicknameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
      );
      
      _loadingOverlay.hide();
      
      if (response['success']) {
        SnackBarUtils.showSuccess(context, 'Successfully joined group!');
        Navigator.of(context).pop(true);
      } else {
        SnackBarUtils.showError(context, response['message'] ?? 'Failed to join group');
      }
    } catch (e) {
      _loadingOverlay.hide();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Member'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Member Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your details to join the group',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname *',
                  hintText: 'Enter your nickname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nickname is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createMember,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Join Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 