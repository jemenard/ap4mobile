import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/festival.dart';

class PaymentPage extends StatefulWidget {
  final Festival festival;
  final int fullPriceCount;
  final int studentCount;
  final int childCount;
  final double totalPrice;

  const PaymentPage({
    super.key,
    required this.festival,
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

      // Simulation d'un traitement de paiement
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isProcessing = false);

      if (mounted) {
        // Afficher un message de succès
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text("Paiement réussi !"),
            content: Text(
              "Votre commande de ${widget.fullPriceCount + widget.studentCount + widget.childCount} billet(s) a été confirmée.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Retour à la page d'accueil
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        );
      }
    }
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
                        widget.festival.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.fullPriceCount > 0)
                        _buildTicketSummaryRow(
                          "Tarif plein",
                          widget.fullPriceCount,
                          widget.festival.prix,
                        ),
                      if (widget.studentCount > 0)
                        _buildTicketSummaryRow(
                          "Tarif étudiant",
                          widget.studentCount,
                          widget.festival.prix * 0.80,
                        ),
                      if (widget.childCount > 0)
                        _buildTicketSummaryRow(
                          "Enfant - 10 ans",
                          widget.childCount,
                          widget.festival.prix * 0.70,
                        ),
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
