import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/pet.dart';
import '../../pet/pet_detail_screen.dart';
import '../../pet/pet_card.dart';
import '../../pet/add_pet_screen.dart';

class MyPetsTab extends StatefulWidget {
  const MyPetsTab({super.key});

  @override
  State<MyPetsTab> createState() => _MyPetsTabState();
}

class _MyPetsTabState extends State<MyPetsTab> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PetProvider>(context, listen: false).loadMyPets();
    });
  }

  List<Pet> _getFilteredPets(List<Pet> pets) {
    switch (_selectedFilter) {
      case 'available':
        return pets.where((pet) => pet.status == 'available').toList();
      case 'adopted':
        return pets.where((pet) => pet.status == 'adopted').toList();
      case 'all':
      default:
        return pets;
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPetScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Pet',
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          if (petProvider.isLoading && petProvider.myPets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.myPets.isEmpty) {
            return _EmptyState();
          }

          final filteredPets = _getFilteredPets(petProvider.myPets);

          return RefreshIndicator(
            onRefresh: () async {
              await petProvider.loadMyPets();
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
                          const Color(0xFFE6A43B),
                          const Color(0xFFE6A43B).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${filteredPets.length} Pets',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getStatsText(petProvider.myPets),
                                style: const TextStyle(
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

                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All (${petProvider.myPets.length})',
                          isSelected: _selectedFilter == 'all',
                          onSelected: () => _onFilterSelected('all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Available (${_getAvailableCount(petProvider.myPets)})',
                          isSelected: _selectedFilter == 'available',
                          onSelected: () => _onFilterSelected('available'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Adopted (${_getAdoptedCount(petProvider.myPets)})',
                          isSelected: _selectedFilter == 'adopted',
                          onSelected: () => _onFilterSelected('adopted'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                if (filteredPets.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyFilterState(
                      filter: _selectedFilter,
                      onClearFilter: () => _onFilterSelected('all'),
                    ),
                  )
                else
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
                          final pet = filteredPets[index];
                          return Hero(
                            tag: 'pet_${pet.id}',
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
                        childCount: filteredPets.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddPetScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFE6A43B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getStatsText(List<Pet> pets) {
    final available = _getAvailableCount(pets);
    final adopted = _getAdoptedCount(pets);
    
    if (available == 0 && adopted == 0) {
      return 'Ready to find homes';
    }
    
    List<String> parts = [];
    if (available > 0) parts.add('$available available');
    if (adopted > 0) parts.add('$adopted adopted');
    
    return parts.join(' • ');
  }

  int _getAvailableCount(List<Pet> pets) {
    return pets.where((pet) => pet.status == 'available').length;
  }

  int _getAdoptedCount(List<Pet> pets) {
    return pets.where((pet) => pet.status == 'adopted').length;
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum Pet Ainda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajude pets a encontrar lares amorosos adicionando-os para adoção',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddPetScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6A43B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Adicione Seu Primeiro Pet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final String filter;
  final VoidCallback onClearFilter;

  const _EmptyFilterState({
    required this.filter,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'available':
        message = 'No available pets';
        icon = Icons.pets_outlined;
        break;
      case 'adopted':
        message = 'No adopted pets yet';
        icon = Icons.favorite_outline;
        break;
      default:
        message = 'No pets found';
        icon = Icons.search_off;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('Mostrar Todos os Pets'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE6A43B).withOpacity(0.2),
      checkmarkColor: const Color(0xFFE6A43B),
      side: BorderSide(
        color: isSelected ? const Color(0xFFE6A43B) : Colors.grey.shade300,
      ),
    );
  }
} 