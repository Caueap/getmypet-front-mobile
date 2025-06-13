import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/adoption.dart';
import '../../../services/api_service.dart';
import '../../../providers/pet_provider.dart';
import 'package:provider/provider.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Adoption> _myApplications = [];
  List<Adoption> _receivedApplications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final myApps = await _apiService.getMyApplications();
      final receivedApps = await _apiService.getMyPetsApplications();
      
      setState(() {
        _myApplications = myApps;
        _receivedApplications = receivedApps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String status, {String? notes}) async {
    try {
      await _apiService.updateAdoptionStatus(
        adoptionId: applicationId,
        status: status,
        ownerNotes: notes,
      );
      
      await _loadApplications();
      
      if (status == 'completed') {
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        await petProvider.loadAllPets();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.toLowerCase()} successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update application: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActionDialog(Adoption adoption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Application for: ${adoption.pet?.name ?? 'Unknown Pet'}'),
            const SizedBox(height: 8),
            Text('From: ${adoption.applicant?.name ?? 'Unknown User'}'),
            const SizedBox(height: 8),
            Text('Status: ${adoption.statusDisplayName}'),
            if (adoption.message != null && adoption.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(adoption.message!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (adoption.isPending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(adoption.id, 'rejected');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(adoption.id, 'approved');
              },
              child: const Text('Approve'),
            ),
          ],
          if (adoption.isApproved) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateApplicationStatus(adoption.id, 'completed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Complete Adoption'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'My Applications',
              icon: const Icon(Icons.send),
            ),
            Tab(
              text: 'Received',
              icon: const Icon(Icons.inbox),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyApplicationsTab(),
          
          _buildReceivedApplicationsTab(),
        ],
      ),
    );
  }

  Widget _buildMyApplicationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_myApplications.isEmpty) {
      return _buildEmptyState(
        'No Applications Yet',
        'Your adoption applications will appear here',
        Icons.send_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myApplications.length,
        itemBuilder: (context, index) {
          final application = _myApplications[index];
          return _ApplicationCard(
            adoption: application,
            isOwner: false,
            onTap: null,
          );
        },
      ),
    );
  }

  Widget _buildReceivedApplicationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_receivedApplications.isEmpty) {
      return _buildEmptyState(
        'No Applications Received',
        'Applications for your pets will appear here',
        Icons.inbox_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedApplications.length,
        itemBuilder: (context, index) {
          final application = _receivedApplications[index];
          return _ApplicationCard(
            adoption: application,
            isOwner: true,
            onTap: () => _showActionDialog(application),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadApplications,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Adoption adoption;
  final bool isOwner;
  final VoidCallback? onTap;

  const _ApplicationCard({
    required this.adoption,
    required this.isOwner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adoption.pet?.name ?? 'Unknown Pet',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOwner 
                            ? 'From: ${adoption.applicant?.name ?? 'Unknown'}'
                            : 'To: ${adoption.owner?.name ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(adoption.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      adoption.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (adoption.pet != null) ...[
                Row(
                  children: [
                    Icon(
                      adoption.pet!.gender.toLowerCase() == 'male' 
                          ? Icons.male : Icons.female,
                      size: 16,
                      color: adoption.pet!.gender.toLowerCase() == 'male' 
                          ? Colors.blue : Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    Text('${adoption.pet!.gender} • '),
                    Text('${adoption.pet!.age} years • '),
                    Text(adoption.pet!.size),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              if (adoption.message != null && adoption.message!.isNotEmpty) ...[
                const Text(
                  'Message:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adoption.message!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              if (!isOwner && adoption.ownerNotes != null && adoption.ownerNotes!.isNotEmpty) ...[
                const Text(
                  'Owner Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adoption.ownerNotes!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applied: ${DateFormat('MMM dd, yyyy').format(adoption.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (isOwner && onTap != null)
                    const Text(
                      'Tap to manage',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE6A43B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 