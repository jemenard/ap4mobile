import 'package:flutter/material.dart';

class InfoFestivalWidget extends StatefulWidget {
  final String nomFestival;
  final String Desc;
  final String nomGroupe;
  final String lienImg;

  const InfoFestivalWidget({
    super.key,
    required this.nomFestival,
    required this.Desc,
    required this.nomGroupe,
    required this.lienImg,
  });

  @override
  State<InfoFestivalWidget> createState() => _InfoFestivalState();
}

class _InfoFestivalState extends State<InfoFestivalWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              widget.lienImg,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 80),
            ),

            const SizedBox(height: 10),

            Text(
              widget.nomFestival,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text(
              widget.nomGroupe,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),

            const SizedBox(height: 10),

            Text(widget.Desc),
          ],
        ),
      ),
    );
  }
}
