import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../constants/app_constants.dart';

/// Segment calculation details for a rate period
class RateSegmentDetail {
  final int index;
  final int playerCount;
  final double ratePerHour;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final double elapsedMinutes;
  final double cost;

  const RateSegmentDetail({
    required this.index,
    required this.playerCount,
    required this.ratePerHour,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.elapsedMinutes,
    required this.cost,
  });
}

/// Complete real-time calculation breakdown for a game session
class LiveSessionCalculation {
  final Duration totalDuration;
  final double totalGamingCost;
  final double totalMarketCost;
  final double rawGrandTotal;
  final double grandTotal;
  final double roundingDiscount;
  final List<RateSegmentDetail> segments;

  const LiveSessionCalculation({
    required this.totalDuration,
    required this.totalGamingCost,
    required this.totalMarketCost,
    required this.rawGrandTotal,
    required this.grandTotal,
    this.roundingDiscount = 0.0,
    required this.segments,
  });
}

/// Service responsible for real-time minute/second calculations and live session ticking
class SessionTimerService {
  static final SessionTimerService _instance = SessionTimerService._internal();
  factory SessionTimerService() => _instance;
  SessionTimerService._internal();

  Timer? _tickerTimer;
  final ValueNotifier<int> _tickerNotifier = ValueNotifier<int>(0);

  /// ValueListenable to trigger UI updates every second/minute
  ValueListenable<int> get ticker => _tickerNotifier;

  /// Starts the global timer ticker if not already running
  void startGlobalTicker() {
    if (_tickerTimer != null && _tickerTimer!.isActive) return;
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickerNotifier.value = timer.tick;
    });
  }

  /// Stops global ticker if no active sessions need ticking
  void stopGlobalTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  /// Floor rounding to nearest 250 IQD (0, 250, 500, 750)
  /// Examples: 1605 -> 1500, 1650 -> 1500, 3800 -> 3750
  static double calculateRoundedTotal(double rawTotal) {
    if (rawTotal <= 0) return 0.0;
    return (rawTotal / 250.0).floor() * 250.0;
  }

  /// Calculates real-time cost for an elapsed duration at a given hourly rate
  /// Formula: (elapsedMinutes / 60.0) * ratePerHour
  static double calculateCost({
    required Duration duration,
    required double ratePerHour,
  }) {
    final minutes = duration.inSeconds / 60.0;
    final cost = (minutes / 60.0) * ratePerHour;
    return double.parse(cost.toStringAsFixed(4));
  }

  /// Performs detailed calculation across all rate segments in a session
  static LiveSessionCalculation calculateSession({
    required GameSessionModel session,
    DateTime? atTime,
  }) {
    final effectiveNow = atTime ?? session.endTime ?? DateTime.now();
    final List<RateSegmentDetail> segmentDetails = [];
    double accumulatedGamingCost = 0.0;

    if (session.rateHistory.isEmpty) {
      // Fallback to single segment
      final segmentEnd = session.endTime ?? effectiveNow;
      final segmentDuration = segmentEnd.isBefore(session.startTime)
          ? Duration.zero
          : segmentEnd.difference(session.startTime);
      final segmentMinutes = segmentDuration.inSeconds / 60.0;
      final cost = double.parse(((segmentMinutes / 60.0) * session.pricingRate).toStringAsFixed(4));

      segmentDetails.add(RateSegmentDetail(
        index: 1,
        playerCount: session.playerCount,
        ratePerHour: session.pricingRate,
        startedAt: session.startTime,
        endedAt: segmentEnd,
        duration: segmentDuration,
        elapsedMinutes: segmentMinutes,
        cost: cost,
      ));
      accumulatedGamingCost = cost;
    } else {
      for (int i = 0; i < session.rateHistory.length; i++) {
        final history = session.rateHistory[i];
        final segmentEnd = history.endedAt ?? effectiveNow;
        final segmentDuration = segmentEnd.isBefore(history.startedAt)
            ? Duration.zero
            : segmentEnd.difference(history.startedAt);
        final segmentMinutes = segmentDuration.inSeconds / 60.0;

        double cost;
        if (history.costForDuration != null && history.endedAt != null) {
          cost = history.costForDuration!;
        } else {
          cost = double.parse(((segmentMinutes / 60.0) * history.ratePerHour).toStringAsFixed(4));
        }

        segmentDetails.add(RateSegmentDetail(
          index: i + 1,
          playerCount: history.playerCount,
          ratePerHour: history.ratePerHour,
          startedAt: history.startedAt,
          endedAt: segmentEnd,
          duration: segmentDuration,
          elapsedMinutes: segmentMinutes,
          cost: cost,
        ));
        accumulatedGamingCost += cost;
      }
    }

    final totalMarketCost = session.calculateTotalMarketCost();
    final totalDuration = session.getElapsedDuration(atTime: effectiveNow);
    final rawTotal = double.parse((accumulatedGamingCost + totalMarketCost).toStringAsFixed(4));
    final roundedTotal = calculateRoundedTotal(rawTotal);
    final roundingDiscount = double.parse((rawTotal - roundedTotal).toStringAsFixed(4));

    return LiveSessionCalculation(
      totalDuration: totalDuration,
      totalGamingCost: accumulatedGamingCost,
      totalMarketCost: totalMarketCost,
      rawGrandTotal: rawTotal,
      grandTotal: roundedTotal,
      roundingDiscount: roundingDiscount,
      segments: segmentDetails,
    );
  }

  /// Calculates the rate change transitions and returns the new session object
  static GameSessionModel applyPlayerCountChange({
    required GameSessionModel session,
    required int newPlayerCount,
    DateTime? switchTime,
  }) {
    if (session.playerCount == newPlayerCount) return session;

    final now = switchTime ?? DateTime.now();
    final newRate = AppConstants.getRateForPlayers(newPlayerCount);
    final updatedHistory = <RateChangeHistory>[];

    // Close open segments
    for (final seg in session.rateHistory) {
      if (seg.endedAt == null) {
        updatedHistory.add(seg.closeWithEndTime(now));
      } else {
        updatedHistory.add(seg);
      }
    }

    // Add new segment
    updatedHistory.add(RateChangeHistory(
      playerCount: newPlayerCount,
      ratePerHour: newRate,
      startedAt: now,
      endedAt: null,
      costForDuration: null,
    ));

    final calc = calculateSession(
      session: session.copyWith(
        playerCount: newPlayerCount,
        pricingRate: newRate,
        rateHistory: updatedHistory,
      ),
      atTime: now,
    );

    return session.copyWith(
      playerCount: newPlayerCount,
      pricingRate: newRate,
      rateHistory: updatedHistory,
      totalGamingCost: calc.totalGamingCost,
      totalMarketCost: calc.totalMarketCost,
      totalAmount: calc.grandTotal,
    );
  }
}
