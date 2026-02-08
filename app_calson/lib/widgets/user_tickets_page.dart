import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/ticket.dart';
import 'package:intl/intl.dart';

class UserTicketsPage extends StatefulWidget {
  const UserTicketsPage({super.key});

  @override
  State<UserTicketsPage> createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ticket>>(
      future: _databaseService.getUserTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tickets = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return _buildTicketCard(tickets[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Aucun ticket trouvé",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Vos réservations apparaîtront ici."),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 10,
                color: ticket.isPass ? const Color(0xFF13293d) : Colors.orange,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.eventName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (ticket.isPass ? const Color(0xFF13293d) : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.isPass ? "PASS" : "TICKET",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ticket.isPass ? const Color(0xFF13293d) : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ticket.date.isNotEmpty) ...[
                        _buildInfoRow(Icons.calendar_today, _formatDate(ticket.date)),
                        const SizedBox(height: 4),
                      ],
                      if (ticket.location.isNotEmpty) ...[
                        _buildInfoRow(Icons.location_on, ticket.location),
                        const SizedBox(height: 4),
                      ],
                      _buildInfoRow(Icons.person, "Type : ${ticket.type}"),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Prix payé",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            "${ticket.price.toStringAsFixed(2)} €",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
