import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/festival.dart';
import '../models/manifestation.dart';
import '../services/database_service.dart';

class PaymentPage extends StatefulWidget {
  final Festival festival;
  final Manifestation? manifestation;
  final int fullPriceCount;
  final int studentCount;
  final int childCount;
  final double totalPrice;

  const PaymentPage({
    super.key,
    required this.festival,
    this.manifestation,
    required this.fullPriceCount,
    required this.studentCount,
    required this.childCount,
    required this.totalPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      final dbService = DatabaseService();
      bool allSuccessful = true;
      int successCount = 0;
      int? firstReservationId;
      int totalToReserve = widget.fullPriceCount + widget.studentCount + widget.childCount;

      try {
        // Obtenir le prix de base
        double basePrice = widget.manifestation?.numericPrix ?? widget.festival.prix;

        // 1. Réserver les billets Plein Tarif
        for (int i = 0; i < widget.fullPriceCount; i++) {
          int? id = await dbService.reserverTicket(
            festivalId: widget.festival.id,
            manifestationId: widget.manifestation?.id,
            type: "Plein tarif",
            prix: basePrice,
          );
          if (id != null) {
            successCount++;
            firstReservationId ??= id;
          } else {
            allSuccessful = false;
          }
        }

        // 2. Réserver les billets Étudiant
        for (int i = 0; i < widget.studentCount; i++) {
          int? id = await dbService.reserverTicket(
            festivalId: widget.festival.id,
            manifestationId: widget.manifestation?.id,
            type: "Tarif étudiant",
            prix: basePrice * 0.80,
          );
          if (id != null) {
            successCount++;
            firstReservationId ??= id;
          } else {
            allSuccessful = false;
          }
        }

        // 3. Réserver les billets Enfant
        for (int i = 0; i < widget.childCount; i++) {
          int? id = await dbService.reserverTicket(
            festivalId: widget.festival.id,
            manifestationId: widget.manifestation?.id,
            type: "Enfant - 10 ans",
            prix: basePrice * 0.70,
          );
          if (id != null) {
            successCount++;
            firstReservationId ??= id;
          } else {
            allSuccessful = false;
          }
        }

        // Envoi de l'email de confirmation si au moins une réservation a réussi
        if (firstReservationId != null) {
          await dbService.sendConfirmationEmail(firstReservationId);
        }

        setState(() => _isProcessing = false);

        if (mounted) {
          if (allSuccessful) {
            _showSuccessDialog();
          } else if (successCount > 0) {
            _showPartialSuccessDialog(successCount, totalToReserve);
          } else {
            _showErrorDialog("Échec de la réservation. Veuillez réessayer.");
          }
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          String message = e.toString();
          if (message.startsWith("Exception: ")) {
            message = message.substring(11);
          }
          _showErrorDialog("Une erreur est survenue : $message");
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text("Paiement réussi !"),
        content: Text(
          "Vos ${widget.fullPriceCount + widget.studentCount + widget.childCount} billet(s) ont été réservés avec succès.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    );
  }

  void _showPartialSuccessDialog(int success, int total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 64),
        title: const Text("Paiement partiel"),
        content: Text(
          "Seulement $success sur $total billets ont pu être réservés. Veuillez contacter le support.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif de la commande
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Récapitulatif",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        widget.manifestation?.titre ?? widget.festival.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.manifestation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Festival : ${widget.festival.name}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Calcul du prix de base
                      (() {
                        final double basePrice = widget.manifestation?.numericPrix ?? widget.festival.prix;
                        
                        return Column(
                          children: [
                            if (widget.fullPriceCount > 0)
                              _buildTicketSummaryRow(
                                "Tarif plein",
                                widget.fullPriceCount,
                                basePrice,
                              ),
                            if (widget.studentCount > 0)
                              _buildTicketSummaryRow(
                                "Tarif étudiant",
                                widget.studentCount,
                                basePrice * 0.80,
                              ),
                            if (widget.childCount > 0)
                              _buildTicketSummaryRow(
                                "Enfant - 10 ans",
                                widget.childCount,
                                basePrice * 0.70,
                              ),
                          ],
                        );
                      })(),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${widget.totalPrice.toStringAsFixed(2)} €",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Formulaire de paiement
              const Text(
                "Informations de paiement",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Numéro de carte
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: "Numéro de carte",
                  hintText: "1234 5678 9012 3456",
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer le numéro de carte";
                  }
                  if (value.replaceAll(' ', '').length < 16) {
                    return "Le numéro de carte doit contenir 16 chiffres";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date d'expiration et CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: "Date d'expiration",
                        hintText: "MM/AA",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requis";
                        }
                        if (value.length < 5) {
                          return "Format MM/AA";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: "CVV",
                        hintText: "123",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requis";
                        }
                        if (value.length < 3) {
                          return "3 chiffres";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Nom du titulaire
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: "Nom du titulaire",
                  hintText: "JEAN DUPONT",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer le nom du titulaire";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Bouton de paiement
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing
                        ? "Traitement en cours..."
                        : "Payer ${widget.totalPrice.toStringAsFixed(2)} €",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message de sécurité
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    "Paiement sécurisé",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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

  Widget _buildTicketSummaryRow(String label, int count, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label × $count"),
          Text(
            "${(count * price).toStringAsFixed(2)} €",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Formateur pour le numéro de carte (ajoute des espaces tous les 4 chiffres)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formateur pour la date d'expiration (format MM/AA)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
