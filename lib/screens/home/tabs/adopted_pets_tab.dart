import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../pet/pet_detail_screen.dart';
import '../../pet/pet_card.dart';

class AdoptedPetsTab extends StatefulWidget {
  const AdoptedPetsTab({super.key});

  @override
  State<AdoptedPetsTab> createState() => _AdoptedPetsTabState();
}

class _AdoptedPetsTabState extends State<AdoptedPetsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        petProvider.loadAdoptedPets(authProvider.currentUser!.id);
      }
    });
  }

  void _navigateToExplore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mude para a aba Explorar para encontrar pets para adotar!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets Adotados'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<PetProvider, AuthProvider>(
        builder: (context, petProvider, authProvider, child) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = authProvider.currentUser?.id ?? '';
          final adoptedPets = petProvider.getAdoptedPetsByUser(userId);

          if (adoptedPets.isEmpty) {
            return _EmptyState(onNavigateToExplore: _navigateToExplore);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await petProvider.loadAllPets();
              petProvider.loadAdoptedPets(userId);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${adoptedPets.length} Pets Adotados',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Obrigado por dar um lar amoroso a eles! 🏠',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pet = adoptedPets[index];
                        if (pet == null) {
                          return const SizedBox.shrink();
                        }
                        
                        return Hero(
                          tag: 'adopted_pet_${pet.id}',
                          child: PetCard(
                            pet: pet,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PetDetailScreen(pet: pet),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: adoptedPets.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNavigateToExplore;

  const _EmptyState({required this.onNavigateToExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum Pet Adotado Ainda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quando você adotar pets, eles aparecerão aqui',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onNavigateToExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Encontre Pets para Adotar'),
            ),
          ],
        ),
      ),
    );
  }
} 