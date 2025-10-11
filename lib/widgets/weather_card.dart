import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String city;
  final String temperature;
  final String description;
  final String icon;

  const WeatherCard({
    super.key,
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              city,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Image.network(
              "https://openweathermap.org/img/wn/$icon@2x.png",
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 10),
            Text(
              "$temperature°C",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
            ),
            Text(
              description.toUpperCase(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
