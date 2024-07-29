import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';
  double rate = 0.0;
  double total = 0.0;
  TextEditingController amountController = TextEditingController();
  List<String> currencies = [];
  bool isLoading = true;
  DateTime lastUpdatedAt = DateTime.now();
  DateTime nextUpdateAt = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    } else {
      _getCurrencies();
    }
  }

  Future<void> _getCurrencies() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://v6.exchangerate-api.com/v6/b76c3563d9309941bfe85ce6/latest/USD'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          currencies =
              (data['conversion_rates'] as Map<String, dynamic>).keys.toList();
          rate = data['conversion_rates'][toCurrency];
          lastUpdatedAt = DateFormat('EEE, d MMM yyyy HH:mm:ss Z')
              .parse(data['time_last_update_utc']);
          nextUpdateAt = DateFormat('EEE, d MMM yyyy HH:mm:ss Z')
              .parse(data['time_next_update_utc']);
        });
      } else {
        _showNoInternetDialog();
      }
    } catch (error) {
      _showNoInternetDialog();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getRate() async {
    setState(() {
      isLoading = true;
    });
    try {
      var response = await http.get(Uri.parse(
          'https://v6.exchangerate-api.com/v6/b76c3563d9309941bfe85ce6/latest/$fromCurrency'));

      var data = json.decode(response.body);

      setState(() {
        rate = data['conversion_rates'][toCurrency];
      });
    } catch (e) {
      _showNoInternetDialog();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      _getRate();
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
              'Please check your internet connection and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectivity();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor('#00171f'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Currency Converter'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: HexColor('#ffffff'),
                semanticsLabel: 'Loading...',
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/currency_bg.png',
                            width: MediaQuery.of(context).size.width / 4,
                          ),
                          Column(
                            children: [
                              Text(
                                'Last updated at ${formatDate(lastUpdatedAt)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Next update at ${formatDate(nextUpdateAt)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != '') {
                            setState(() {
                              double amount = double.parse(value);
                              total = amount * rate;
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 100,
                            child: DropdownButton<String>(
                              value: fromCurrency,
                              isExpanded: true,
                              dropdownColor: HexColor('#051923'),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              items: currencies.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  fromCurrency = newValue!;
                                  _getRate();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _swapCurrencies,
                            icon: const Icon(
                              Icons.swap_horiz,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButton<String>(
                              value: toCurrency,
                              isExpanded: true,
                              dropdownColor: HexColor('#051923'),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              items: currencies.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  toCurrency = newValue!;
                                  _getRate();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Today's Rate $rate",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      total.toStringAsFixed(2),
                      style: TextStyle(
                        color: HexColor('#007ea7'),
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
