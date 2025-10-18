import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../widgets/weather_card.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          tooltip: 'Back to Home',
        ),
        title: const Text(
          "Météo actuelle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[400]!,
              Colors.blue[200]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher une ville...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() => city = value);
                        fetchWeather();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Weather Content
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : weatherData != null
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Main Weather Card
                                  _buildMainWeatherCard(),
                                  const SizedBox(height: 20),
                                  // Additional Info Cards
                                  _buildWeatherDetailsGrid(),
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Aucune donnée météo disponible",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    final temp = weatherData["main"]["temp"].toStringAsFixed(1);
    final description = weatherData["weather"][0]["description"];
    final icon = weatherData["weather"][0]["icon"];
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // City Name
          Text(
            city,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 10),
          // Weather Icon
          Image.network(
            "https://openweathermap.org/img/wn/$icon@4x.png",
            width: 150,
            height: 150,
          ),
          // Temperature
          Text(
            "$temp°C",
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          // Description
          Text(
            description.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Feels Like
          Text(
            "Ressenti: ${weatherData["main"]["feels_like"].toStringAsFixed(1)}°C",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _buildDetailCard(
          icon: Icons.water_drop,
          title: "Humidité",
          value: "${weatherData["main"]["humidity"]}%",
          color: Colors.blue,
        ),
        _buildDetailCard(
          icon: Icons.air,
          title: "Vent",
          value: "${weatherData["wind"]["speed"]} m/s",
          color: Colors.teal,
        ),
        _buildDetailCard(
          icon: Icons.compress,
          title: "Pression",
          value: "${weatherData["main"]["pressure"]} hPa",
          color: Colors.orange,
        ),
        _buildDetailCard(
          icon: Icons.thermostat,
          title: "Min / Max",
          value: "${weatherData["main"]["temp_min"].toStringAsFixed(0)}° / ${weatherData["main"]["temp_max"].toStringAsFixed(0)}°",
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
