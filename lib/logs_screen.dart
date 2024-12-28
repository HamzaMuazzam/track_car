import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LogsScreen extends StatefulWidget {
  final String collectionName;

  LogsScreen({Key? key, required this.collectionName}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 100;
  final List<DocumentSnapshot> _documentSnapshots = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  late Stream<QuerySnapshot> _realTimeStream;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      print("collectionName");
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMoreData) {
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection(widget.collectionName)
        .orderBy('time', descending: true)
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = snapshot.docs.last;
          _documentSnapshots.addAll(snapshot.docs);
          if (snapshot.docs.length < _pageSize) {
            _hasMoreData = false;
          }
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionName),
      ),
      body: _documentSnapshots.isEmpty && !_isLoading
          ? const Center(child: Text('No data available.'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Time")),
                        DataColumn(label: Text("Reason")),
                        DataColumn(label: Text("Speed")),
                        DataColumn(label: Text("Latitude")),
                        DataColumn(label: Text("Longitude")),
                        DataColumn(label: Text("Provider")),
                        DataColumn(label: Text("Version No")),
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Accuracy")),
                        DataColumn(label: Text("Altitude")),
                        DataColumn(label: Text("Bearing")),
                        DataColumn(label: Text("Device RDT")),
                        DataColumn(label: Text("Email Address")),
                      ],
                      rows: _documentSnapshots
                          .map(
                            (doc) => _buildDataRow(LocationData.fromFireStore(doc.data() as Map<String, dynamic>),),
                      ).toList(),
                    ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }

  DataRow _buildDataRow(LocationData data) {
    return DataRow(
      cells: [
        DataCell(
            Text(data.time != null ? data.time!.toLocal().toString() : "N/A")),
        DataCell(Text(data.reason ?? "N/A")),
        DataCell(Text(data.speed?.toString() ?? "N/A")),
        DataCell(Text(data.latitude?.toStringAsFixed(6) ?? "N/A")),
        DataCell(Text(data.longitude?.toStringAsFixed(6) ?? "N/A")),
        DataCell(Text(data.provider ?? "N/A")),
        DataCell(Text(data.versionNo ?? "N/A")),
        DataCell(Text(data.name ?? "N/A")),
        DataCell(Text(data.accuracy?.toStringAsFixed(2) ?? "N/A")),
        DataCell(Text(data.altitude?.toStringAsFixed(2) ?? "N/A")),
        DataCell(Text(data.bearing?.toString() ?? "N/A")),
        DataCell(Text(data.deviceRDT ?? "N/A")),
        DataCell(Text(data.emailAddress ?? "N/A")),
      ],
    );
  }
}

class LocationData {
  final double? accuracy;
  final double? altitude;
  final dynamic bearing;
  final String? deviceRDT;
  final String? emailAddress;
  final String? gmtSettings;
  final int? igStatus;
  final String? imei;
  final double? latitude;
  final double? longitude;
  final String? name;
  final String? phoneNo;
  final String? provider;
  final String? reason;
  final dynamic speed;
  final DateTime? time;
  final String? versionNo;

  LocationData({
    this.accuracy,
    this.altitude,
    this.bearing,
    this.deviceRDT,
    this.emailAddress,
    this.gmtSettings,
    this.igStatus,
    this.imei,
    this.latitude,
    this.longitude,
    this.name,
    this.phoneNo,
    this.provider,
    this.reason,
    this.speed,
    this.time,
    this.versionNo,
  });

  factory LocationData.fromFireStore(Map<String, dynamic> data) {
    return LocationData(
      name: data['name'],
      accuracy: data['accuracy'],
      altitude: data['altitude'],
      bearing: data['bearing'],
      deviceRDT: data['deviceRDT'],
      emailAddress: data['emailAddress'],
      gmtSettings: data['gmtSettings'],
      igStatus: data['igStatus'],
      imei: data['imei'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      phoneNo: data['phoneNo'],
      provider: data['provider'],
      reason: data['reason'],
      speed: data['speed'],
      time: data['time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['time']).toLocal()
          : null,
      versionNo: data['versionNo'],
    );
  }
}
