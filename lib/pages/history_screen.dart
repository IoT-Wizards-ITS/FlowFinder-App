import 'package:flutter/material.dart';
import 'package:flowfinder/utils/api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<dynamic> historyData = [];
  String selectedApi = '100';

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await fetchData(
        'https://flowfinder-be-dot-protel-e376b.et.r.appspot.com/floodHistory/$selectedApi'
      );

      if (response['status'] == 'success') {
        setState(() {
          historyData = response['data']['latestDiffData'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Flood History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 66, 72, 116),
        actions: [
          DropdownButton<String>(
            value: selectedApi,
            dropdownColor: const Color.fromARGB(255, 66, 72, 116),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(
              height: 2,
              color: Colors.white,
            ),
            onChanged: (String? newValue) {
              setState(() {
                selectedApi = newValue!;
                fetchHistory();
              });
            },
            items: <String>['100', '101', '102']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  'Sensor $value',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: historyData.length,
              itemBuilder: (context, index) {
                final flood = historyData[index];
                return ListTile(
                  title: Text('Duration: ${flood['floodDuration']}'),
                  subtitle: Text(
                    'Start: ${flood['floodedStart']}\nEnd: ${flood['floodedEnd']}',
                  ),
                );
              },
            ),
    );
  }
}
