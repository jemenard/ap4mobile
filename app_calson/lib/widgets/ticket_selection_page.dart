import 'package:flutter/material.dart';
import '../models/festival.dart';
import 'payment_page.dart';

class TicketSelectionPage extends StatefulWidget {
  final Festival festival;

  const TicketSelectionPage({super.key, required this.festival});

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  int fullPriceCount = 0;
  int studentCount = 0;
  int childCount = 0;

  double get fullPrice => widget.festival.prix;
  double get studentPrice => widget.festival.prix * 0.80;
  double get childPrice => widget.festival.prix * 0.70;

  double get totalPrice {
    return (fullPriceCount * fullPrice) +
        (studentCount * studentPrice) +
        (childCount * childPrice);
  }

  int get totalTickets => fullPriceCount + studentCount + childCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sélection des billets"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du festival
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.festival.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.festival.location}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Choisissez vos billets",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Maximum 4 billets par catégorie",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Tarif plein
            _buildTicketCard(
              title: "Tarif plein",
              price: fullPrice,
              count: fullPriceCount,
              onIncrement: () {
                if (fullPriceCount < 4) {
                  setState(() => fullPriceCount++);
                }
              },
              onDecrement: () {
                if (fullPriceCount > 0) {
                  setState(() => fullPriceCount--);
                }
              },
              icon: Icons.person,
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            // Tarif étudiant
            _buildTicketCard(
              title: "Tarif étudiant",
              subtitle: "80% du prix",
              price: studentPrice,
              count: studentCount,
              onIncrement: () {
                if (studentCount < 4) {
                  setState(() => studentCount++);
                }
              },
              onDecrement: () {
                if (studentCount > 0) {
                  setState(() => studentCount--);
                }
              },
              icon: Icons.school,
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            // Tarif enfant
            _buildTicketCard(
              title: "Enfant - 10 ans",
              subtitle: "70% du prix",
              price: childPrice,
              count: childCount,
              onIncrement: () {
                if (childCount < 4) {
                  setState(() => childCount++);
                }
              },
              onDecrement: () {
                if (childCount > 0) {
                  setState(() => childCount--);
                }
              },
              icon: Icons.child_care,
              color: Colors.orange,
            ),

            const SizedBox(height: 32),

            // Récapitulatif
            Card(
              elevation: 4,
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total des billets:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "$totalTickets",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Prix total:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${totalPrice.toStringAsFixed(2)} €",
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

            const SizedBox(height: 24),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: totalTickets > 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(
                              festival: widget.festival,
                              fullPriceCount: fullPriceCount,
                              studentCount: studentCount,
                              childCount: childCount,
                              totalPrice: totalPrice,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.payment),
                label: const Text(
                  "Procéder au paiement",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard({
    required String title,
    String? subtitle,
    required double price,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),

            // Titre et prix
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "${price.toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),

            // Contrôles de quantité
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: count > 0 ? onDecrement : null,
                    icon: const Icon(Icons.remove),
                    color: color,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "$count",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: count < 4 ? onIncrement : null,
                    icon: const Icon(Icons.add),
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
