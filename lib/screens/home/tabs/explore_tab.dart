import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/pet.dart';
import '../../pet/pet_detail_screen.dart';
import '../../pet/pet_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecies = 'Todos';
  List<Pet> _filteredPets = [];

  final List<String> _species = ['Todos', 'Cachorro', 'Gato', 'Outro'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPets() {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    List<Pet> pets = petProvider.availablePets;
    
    if (_selectedSpecies != 'Todos') {
      switch (_selectedSpecies) {
        case 'Cachorro':
          pets = pets.where((pet) => 
            pet.species.toLowerCase() == 'dog'
          ).toList();
          break;
        case 'Gato':
          pets = pets.where((pet) => 
            pet.species.toLowerCase() == 'cat'
          ).toList();
          break;
        case 'Outro':
          pets = pets.where((pet) => 
            pet.species.toLowerCase() == 'other'
          ).toList();
          break;
      }
    }
    
    if (query.isNotEmpty) {
      pets = pets.where((pet) {
        return pet.name.toLowerCase().contains(query) ||
               pet.species.toLowerCase().contains(query) ||
               (pet.breed?.toLowerCase().contains(query) ?? false) ||
               pet.location.toLowerCase().contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredPets = pets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontre seu Pet!'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          if (petProvider.isLoading && petProvider.allPets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (_filteredPets.isEmpty && _searchController.text.isEmpty && _selectedSpecies == 'Todos') {
            _filteredPets = petProvider.availablePets;
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquise por nome, raça ou localização...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: _species.map((species) {
                        final isSelected = species == _selectedSpecies;
                        
                        return Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    species,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSpecies = species;
                                  });
                                  _filterPets();
                                },
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFFE6A43B).withOpacity(0.2),
                                checkmarkColor: const Color(0xFFE6A43B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _filteredPets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pets found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await petProvider.loadAllPets();
                          _filterPets();
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredPets.length,
                          itemBuilder: (context, index) {
                            final pet = _filteredPets[index];
                            return PetCard(
                              pet: pet,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PetDetailScreen(pet: pet),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
} 