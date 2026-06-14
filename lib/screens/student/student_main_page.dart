import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'student_dashboard.dart';
import 'bus_schedule.dart';
import '../../theme.dart';
import '../../widgets/slide_up_route.dart';
import '../../widgets/title_bar.dart';
import '../../maps/location.dart';
import '../../util/permission_helper.dart';

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});

  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  String username = "Loading...";
  String email = "";
  bool isLoading = true;

  String? favoriteBus;
  String? trackedBusNumber;
  LatLng? studentLocation;

  Map<String, LatLng> _allActiveBuses = {};
  List<String> nearestBuses = [];

  LatLng? trackedBusLocation;
  double? trackedBusDistance;
  int? trackedBusEta;
  bool isTrackingBusOnline = false;

  StreamSubscription<DatabaseEvent>? _busesSubscription;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _loadLocalUserData();
    _fetchUserDataFromFirebase();
    _loadCommutePreferences();
    _initLocationAndBuses();
  }

  Future<void> _loadLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "Loading...";
      email = prefs.getString('email') ?? "";
      isLoading = false;
    });
  }

  Future<void> _fetchUserDataFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          username = data['username'] ?? "Unknown Student";
          email = data['email'] ?? user.email ?? "No email";
          isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('email', email);
      } else {
        setState(() {
          username = user.displayName ?? "Unknown Student";
          email = user.email ?? "No email";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
    }
  }

  Future<void> _loadCommutePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        favoriteBus = prefs.getString('favorite_bus');
        trackedBusNumber = prefs.getString('tracked_bus_number');
      });
      _recalculateDistances();
    } catch (e) {
      debugPrint("Error loading commute preferences: $e");
    }
  }

  Future<void> _initLocationAndBuses() async {
    try {
      final permission = await PermissionHelper.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await determinePosition();
        if (mounted) {
          setState(() {
            studentLocation = LatLng(pos.latitude, pos.longitude);
          });
          _recalculateDistances();
        }

        _positionSubscription =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 10,
              ),
            ).listen((newPos) {
              if (mounted) {
                setState(() {
                  studentLocation = LatLng(newPos.latitude, newPos.longitude);
                });
                _recalculateDistances();
              }
            });

        _listenToBuses();
      }
    } catch (e) {
      debugPrint("Error initializing location/buses: $e");
    }
  }

  void _listenToBuses() {
    _busesSubscription = FirebaseDatabase.instance.ref("buses").onValue.listen((
      event,
    ) {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) {
          setState(() {
            _allActiveBuses.clear();
            nearestBuses.clear();
            isTrackingBusOnline = false;
            trackedBusLocation = null;
          });
        }
        return;
      }

      final Map<dynamic, dynamic> busesMap = data as Map;
      final Map<String, LatLng> activeBuses = {};
      busesMap.forEach((key, val) {
        if (val is Map) {
          final lat = double.tryParse(val['latitude'].toString()) ?? 0.0;
          final lng = double.tryParse(val['longitude'].toString()) ?? 0.0;
          activeBuses[key.toString().toUpperCase()] = LatLng(lat, lng);
        }
      });

      if (mounted) {
        setState(() {
          _allActiveBuses = activeBuses;
          _recalculateDistances();
        });
      }
    });
  }

  void _recalculateDistances() {
    if (studentLocation == null) return;

    List<String> nearby = [];
    LatLng? tBusLoc;
    bool tBusOnline = false;
    double? tBusDist;
    int? tBusEta;

    _allActiveBuses.forEach((busNo, busLoc) {
      final dist = _calculateDistance(studentLocation!, busLoc);
      if (dist <= 5.0) {
        nearby.add(busNo);
      }

      if (trackedBusNumber != null &&
          busNo.toUpperCase() == trackedBusNumber!.toUpperCase()) {
        tBusLoc = busLoc;
        tBusOnline = true;
        tBusDist = dist;
        tBusEta = ((dist / 35) * 60).ceil();
      }
    });

    setState(() {
      nearestBuses = nearby;
      isTrackingBusOnline = tBusOnline;
      trackedBusLocation = tBusLoc;
      trackedBusDistance = tBusDist;
      trackedBusEta = tBusEta;
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = (end.latitude - start.latitude) * (pi / 180);
    final dLon = (end.longitude - start.longitude) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) *
            cos(end.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0F131E)
        : const Color(0xFFF4F6FA);
    final surfaceColor = isDark ? const Color(0xFF181D2E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      appBar: const TitleBar(title: 'KIIT BUS'),
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(theme, isDark, surfaceColor, borderColor),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Smart Transit Hub",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Automated",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFavoriteBusCard(
                          theme,
                          isDark,
                          surfaceColor,
                          borderColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNearestBusesCard(
                          theme,
                          isDark,
                          surfaceColor,
                          borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLiveCommuteCard(
                    theme,
                    isDark,
                    surfaceColor,
                    borderColor,
                  ),
// Quick Services section removed as per request
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141928) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(top: BorderSide(color: borderColor, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavButton(
                icon: Icons.dashboard_customize_rounded,
                label: 'Dashboard',
                color: isDark
                    ? const Color(0xFFF57C00)
                    : const Color(0xFFEF6C00),
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideUpRoute(page: const StudentDashboard()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavButton(
                icon: Icons.map_rounded,
                label: 'Schedules',
                color: AppTheme.primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideUpRoute(page: const BusSchedulePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    if (isLoading) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          color: AppTheme.primaryColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 30,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteBusCard(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final hasFav = favoriteBus != null && favoriteBus!.isNotEmpty;
    final isOnline =
        hasFav && _allActiveBuses.containsKey(favoriteBus!.toUpperCase());

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => hasFav
              ? _navigateToTrack(favoriteBus!)
              : _showSetFavoriteBusDialog(),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasFav
                            ? Colors.amber.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: hasFav
                            ? const Color(0xFFFFB300)
                            : Colors.grey.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      onPressed: _showSetFavoriteBusDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  hasFav ? "Bus $favoriteBus" : "No Favorite Set",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasFav)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.blueGrey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? "Active" : "Offline",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.blueGrey,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    "Setup shortcuts",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearestBusesCard(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final hasNearby = nearestBuses.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _showNearestBusesDialog,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    Text(
                      "5 km",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  "Nearby Radar",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentLocation == null
                      ? "Locating Node..."
                      : (hasNearby
                            ? "${nearestBuses.length} online now"
                            : "None detected"),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasNearby
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCommuteCard(
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    if (trackedBusNumber == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.departure_board_rounded,
              size: 40,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 12),
            Text(
              "No Active Tracker Streamed",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Launch a transit route inside your tracking dashboard.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    if (!isTrackingBusOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bus $trackedBusNumber Node Offline",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Vehicle coordinates are waiting for terminal sync.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final double distanceVal = trackedBusDistance ?? 0.0;
    final double rawProgress = (1.0 - (distanceVal / 5.0)).clamp(0.0, 1.0);
    final double alignX = -1.0 + (rawProgress * 2.0);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(
              alpha: isDark ? 0.05 : 0.02,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _navigateToTrack(trackedBusNumber!),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Tracking Route: Bus $trackedBusNumber",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const BoxIdentityPulse(),
                          const SizedBox(width: 6),
                          Text(
                            "LIVE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTrackingMetrics(
                      "Distance Remainder",
                      "${distanceVal.toStringAsFixed(2)} km",
                      theme,
                      isDark,
                    ),
                    _buildTrackingMetrics(
                      "Estimated Arrival",
                      "${trackedBusEta ?? 0} mins",
                      theme,
                      isDark,
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDark ? Colors.white10 : Colors.black12,
                              AppTheme.primaryColor.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: isDark
                              ? const Color(0xFF232B45)
                              : const Color(0xFFE8ECF5),
                          child: Icon(
                            Icons.home_max_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(alignX, 0.0),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.2,
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingMetrics(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: highlight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: highlight
                ? AppTheme.primaryColor
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildGridButton(
            Icons.support_agent_rounded,
            "Support Desk",
            surfaceColor,
            borderColor,
            () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildGridButton(
            Icons.receipt_long_rounded,
            "History Log",
            surfaceColor,
            borderColor,
            () {},
          ),
        ),
      ],
    );
  }

  Widget _buildGridButton(
    IconData icon,
    String title,
    Color surfaceColor,
    Color borderColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _showSetFavoriteBusDialog() async {
    final controller = TextEditingController(text: favoriteBus);
    await showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.canvasColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 10),
              Text(
                "Set Favorite Bus",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Fleet Registration / Bus ID",
              hintText: "e.g. 18",
              prefixIcon: const Icon(Icons.directions_bus_rounded),
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Discard",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final busNo = controller.text.trim().toUpperCase();
                if (busNo.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('favorite_bus', busNo);
                  setState(() {
                    favoriteBus = busNo;
                  });
                  _recalculateDistances();
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Link"),
            ),
          ],
        );
      },
    );
  }

  void _showNearestBusesDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text(
                "Buses Nearby (5km)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: nearestBuses.isEmpty
              ? const SizedBox(
                  height: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_searching_rounded,
                        color: Colors.grey,
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No active terminals within radius.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: nearestBuses.length,
                    itemBuilder: (context, index) {
                      final busNo = nearestBuses[index];
                      final loc = _allActiveBuses[busNo];
                      double dist = 0.0;
                      if (studentLocation != null && loc != null) {
                        dist = _calculateDistance(studentLocation!, loc);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "Bus $busNo",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${dist.toStringAsFixed(2)} km away",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToTrack(busNo);
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Dismiss",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToTrack(String busNumber) async {
    await Navigator.push(
      context,
      SlideUpRoute(page: StudentDashboard(initialBusNumber: busNumber)),
    );
    _loadCommutePreferences();
  }

  @override
  void dispose() {
    _busesSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

class BoxIdentityPulse extends StatefulWidget {
  const BoxIdentityPulse({super.key});

  @override
  State<BoxIdentityPulse> createState() => _BoxIdentityPulseState();
}

class _BoxIdentityPulseState extends State<BoxIdentityPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
