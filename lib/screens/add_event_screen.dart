import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:familly_blog/models/user_model.dart';

class AddEventScreen extends StatefulWidget {
  final UserModel currentUser;

  const AddEventScreen({super.key, required this.currentUser});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date.')),
      );
      return;
    }

    // Combiner la date et l'heure
    final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );

    setState(() => _isLoading = true);

    try {
      await _supabase.from('events').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'event_date': eventDateTime.toIso8601String(),
        'created_by': widget.currentUser.id,
      });

      if (mounted) {
        Navigator.pop(context, true); // Retourne true si créé avec succès
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('ERREUR COMPLETE : $e'); // Regardez la console / debug console
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = _selectedDate == null
        ? 'Choisir une date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

    final timeFormatted = _selectedTime == null
        ? 'Choisir l\'heure (optionnel)'
        : '${_selectedTime!.hour}h${_selectedTime!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement'),
        backgroundColor: const Color(0xFF245225),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de l\'événement *',
                  hintText: 'ex: Repas de famille, Anniversaire...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lieu',
                  hintText: 'ex: Chez Papy & Mamie, Parc central...',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // DATE & TIME PICKERS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF245225),
                      ),
                      label: Text(dateFormatted),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(
                        Icons.access_time,
                        color: Color(0xFF245225),
                      ),
                      label: Text(timeFormatted),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description / Détails',
                  hintText:
                      'Ajoutez des détails sur ce qu\'il faut apporter...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245225),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publier l\'événement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
