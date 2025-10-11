import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../widgets/weather_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  String city = "Tunis";
  dynamic weatherData;
  bool isLoading = false;

  Future<void> fetchWeather() async {
    setState(() => isLoading = true);
    weatherData = await _weatherService.getWeather(city);
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Météo actuelle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Entrez une ville",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                setState(() => city = value);
                fetchWeather();
              },
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (weatherData != null)
              WeatherCard(
                city: city,
                temperature: weatherData["main"]["temp"].toString(),
                description: weatherData["weather"][0]["description"],
                icon: weatherData["weather"][0]["icon"],
              )
            else
              const Text("Aucune donnée météo disponible."),
          ],
        ),
      ),
    );
  }
}
