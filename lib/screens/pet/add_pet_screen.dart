import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _vaccinationsController = TextEditingController();

  String _selectedSpecies = 'Cachorro';
  String _selectedSize = 'Médio';
  String _selectedGender = 'Macho';
  String _selectedStatus = 'Disponível';
  bool _isNeutered = false;

  final List<String> _species = ['Cachorro', 'Gato', 'Outro'];
  final List<String> _sizes = ['Pequeno', 'Médio', 'Grande'];
  final List<String> _genders = ['Macho', 'Fêmea'];
  final List<String> _statuses = ['Disponível', 'Pendente', 'Adotado'];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _vaccinationsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final petProvider = Provider.of<PetProvider>(context, listen: false);

    List<String> vaccinations = [];
    if (_vaccinationsController.text.isNotEmpty) {
      vaccinations = _vaccinationsController.text
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
    }

    final success = await petProvider.registerPet(
      name: _nameController.text.trim(),
      species: _selectedSpecies,
      breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
      size: _selectedSize,
      age: double.parse(_ageController.text),
      gender: _selectedGender,
      description: _descriptionController.text.trim(),
      images: [],
      status: _selectedStatus,
      vaccinations: vaccinations,
      isNeutered: _isNeutered,
      location: _locationController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet registrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Pet'),
        actions: [
          Consumer<PetProvider>(
            builder: (context, petProvider, child) {
              return TextButton(
                onPressed: petProvider.isLoading ? null : _submitForm,
                child: petProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              );
            },
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Informações básicas'),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do pet *',
                      prefixIcon: Icon(Icons.pets),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira o nome do pet';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedSpecies,
                    decoration: const InputDecoration(
                      labelText: 'Espécie *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _species.map((species) {
                      return DropdownMenuItem(
                        value: species,
                        child: Text(species.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecies = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(
                      labelText: 'Raça (Opcional)',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Idade (anos) *',
                            prefixIcon: Icon(Icons.cake),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Insira a idade';
                            }
                            final age = double.tryParse(value);
                            if (age == null || age < 0 || age > 30) {
                              return 'Idade inválida';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Sexo *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _genders.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedSize,
                    decoration: const InputDecoration(
                      labelText: 'Tamanho *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: _sizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSize = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle('Descrição'),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Fale sobre este pet *',
                      hintText: 'Personalidade, comportamento, necessidades especiais, etc.',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, forneça uma descrição';
                      }
                      if (value.length < 20) {
                        return 'A descrição deve ter pelo menos 20 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle('Localização'),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Localização *',
                      hintText: 'Cidade, Estado',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a localização';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle('Informações de saúde'),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Castrado/Vermifugado'),
                    subtitle: const Text('Este pet foi castrado/vermifugado?'),
                    value: _isNeutered,
                    onChanged: (value) {
                      setState(() {
                        _isNeutered = value;
                      });
                    },
                    secondary: const Icon(Icons.medical_services),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vaccinationsController,
                    decoration: const InputDecoration(
                      labelText: 'Vacinas (Opcional)',
                      hintText: 'Insira as vacinas separadas por vírgulas',
                      prefixIcon: Icon(Icons.vaccines),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle('Disponibilidade'),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  if (petProvider.error != null)
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
                              petProvider.error!,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: petProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: petProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Registrar Pet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2196F3),
      ),
    );
  }
} 