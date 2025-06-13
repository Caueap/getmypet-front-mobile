import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/photo_upload_widget.dart';
import '../user/owner_profile_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  Pet? _currentPet;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
  }

  Future<void> _applyForAdoption() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser?.id == _currentPet?.ownerId) {
      _showError('Você não pode se candidatar para adotar seu próprio pet');
      return;
    }

    final result = await _showApplicationDialog();
    if (result == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.createAdoption(
        petId: _currentPet!.id,
        ownerId: _currentPet!.ownerId,
        message: result,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidatura para adoção enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<String?> _showApplicationDialog() async {
    final TextEditingController messageController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Candidatar-se para adoção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você está se candidatando para adotar ${_currentPet?.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensagem para o proprietário (Opcional)',
                hintText: 'Fale ao proprietário por que você seria um bom candidato para este pet...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, messageController.text.trim()),
            child: const Text('Enviar candidatura'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletePetDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Pet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza de que deseja remover ${_currentPet?.name}?'),
            const SizedBox(height: 8),
            const Text(
              'Isso irá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Remover permanentemente o pet da plataforma'),
            const Text('• Cancelar todas as candidaturas pendentes'),
            const Text('• Excluir todas as fotos e informações'),
            const SizedBox(height: 8),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover Pet'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePet();
    }
  }

  Future<void> _deletePet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final success = await petProvider.deletePet(_currentPet!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        setState(() {
          _error = petProvider.error ?? 'Falha ao remover o pet';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
  }

  Future<void> _refreshPetData() async {
    try {
      print('PetDetailScreen - Atualizando os dados do pet para o ID: ${_currentPet!.id}');
      final updatedPet = await _apiService.getPetById(_currentPet!.id);
      print('PetDetailScreen - Imagens atualizadas do pet: ${updatedPet.images}');
      print('PetDetailScreen - URLs completas das imagens atualizadas do pet: ${updatedPet.fullImageUrls}');
      setState(() {
        _currentPet = updatedPet;
      });
    } catch (e) {
      print('Erro ao atualizar os dados do pet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = _currentPet;
    if (pet == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: pet.fullImageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: pet.fullImageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),
          
          SliverToBoxAdapter(
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
                              pet.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pet.speciesInPortuguese}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(pet.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pet.statusInPortuguese.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.cake,
                          label: 'Idade',
                          value: '${pet.age} anos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: pet.gender.toLowerCase() == 'male' 
                              ? Icons.male : Icons.female,
                          label: 'Sexo',
                          value: pet.genderInPortuguese,
                          iconColor: pet.gender.toLowerCase() == 'male' 
                              ? Colors.blue : Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.straighten,
                          label: 'Tamanho',
                          value: pet.sizeInPortuguese,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localização',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  pet.location,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isOwner = authProvider.currentUser?.id == pet.ownerId;
                      
                      if (isOwner || pet.owner == null) {
                        return Container();
                      }
                      
                      return Column(
                        children: [
                          Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OwnerProfileScreen(owner: pet.owner!),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFFE6A43B),
                                      child: pet.owner!.avatarUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: pet.owner!.avatarUrl,
                                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                                radius: 28,
                                                backgroundImage: imageProvider,
                                                backgroundColor: Colors.transparent,
                                              ),
                                              placeholder: (context, url) => const CircularProgressIndicator(),
                                              errorWidget: (context, url, error) => Text(
                                                pet.owner!.name.isNotEmpty ? pet.owner!.name[0].toUpperCase() : 'U',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              pet.owner!.name.isNotEmpty ? pet.owner!.name[0].toUpperCase() : 'U',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Proprietário',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            pet.owner!.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (pet.owner!.city.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${pet.owner!.city}${pet.owner!.state.isNotEmpty ? ', ${pet.owner!.state}' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  
                  const Text(
                    'Sobre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Informações de saúde',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(
                        pet.isNeutered ? Icons.check_circle : Icons.cancel,
                        color: pet.isNeutered ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pet.isNeutered ? 'Castrado/Vermifugado' : 'Não castrado/Não vermifugado',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (pet.vaccinations.isNotEmpty) ...[
                    const Text(
                      'Vacinas:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pet.vaccinations.map((vaccination) {
                        return Chip(
                          label: Text(vaccination),
                          backgroundColor: Colors.green.shade50,
                          side: BorderSide(color: Colors.green.shade200),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isOwner = authProvider.currentUser?.id == pet.ownerId;
                      
                      if (!isOwner) {
                        return Container();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gerenciar fotos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PhotoUploadWidget(
                            petId: pet.id,
                            onPhotosUploaded: () {
                              _refreshPetData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fotos enviadas! Puxe para atualizar para ver as alterações.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Ações do proprietário',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showDeletePetDialog(context),
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              label: const Text(
                                'Remover Pet',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),
                  
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isOwner = authProvider.currentUser?.id == pet.ownerId;
                      final isAvailable = pet.status == 'available';
                      
                      if (!isAvailable || isOwner) {
                        return Container();
                      }
                      
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _applyForAdoption,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE6A43B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Candidatar-se para adoção',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'adopted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: iconColor ?? const Color(0xFFE6A43B),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 